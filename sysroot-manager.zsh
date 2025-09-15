#!/usr/bin/env zsh

# Sysroot Manager - A zsh script for managing GCC versions with sysroots
# Author: GitHub Copilot
# Version: 1.0.0

SYSROOTS_CONFIG="$HOME/.sysroots.json"
TEMP_ENV_DIR="/tmp"
CURRENT_SYSROOT_FILE="$HOME/.current_sysroot"
PATH_BACKUP_FILE="$HOME/.path_backup"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Internal color print functions
_sysroot_print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
_sysroot_print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
_sysroot_print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
_sysroot_print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

_sysroot_init_sysroots_config() {
    if [[ ! -f "$SYSROOTS_CONFIG" ]]; then
        echo '{"sysroots": []}' > "$SYSROOTS_CONFIG"
    _sysroot_print_info "Created sysroots configuration at $SYSROOTS_CONFIG"
    fi
}

_sysroot_check_jq() {
    if ! command -v jq &> /dev/null; then
    _sysroot_print_error "jq is required but not installed. Please install jq first."
        echo "  On Ubuntu/Debian: sudo apt-get install jq"
        echo "  On CentOS/RHEL: sudo yum install jq"
        echo "  On macOS: brew install jq"
        return 1
    fi
    return 0
}

_sysroot_detect_gcc_version() {
    local sysroot_path="$1"
    local gcc_path
    
    # Look for gcc in common locations within the sysroot
    for gcc_candidate in "$sysroot_path/bin/gcc" "$sysroot_path/usr/bin/gcc" "$sysroot_path/bin/"*-gcc; do
        if [[ -x "$gcc_candidate" ]]; then
            gcc_path="$gcc_candidate"
            break
        fi
    done
    
    if [[ -n "$gcc_path" ]]; then
        local version=$("$gcc_path" --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        echo "${version:-unknown}"
    else
        echo "unknown"
    fi
}

_sysroot_detect_target_triplet() {
    local sysroot_path="$1"
    local gcc_path
    
    for gcc_candidate in "$sysroot_path/bin/gcc" "$sysroot_path/usr/bin/gcc" "$sysroot_path/bin/"*-gcc; do
        if [[ -x "$gcc_candidate" ]]; then
            gcc_path="$gcc_candidate"
            break
        fi
    done
    
    if [[ -n "$gcc_path" ]]; then
        local target=$("$gcc_path" -dumpmachine 2>/dev/null)
        echo "${target:-unknown}"
    else
        echo "unknown"
    fi
}

_sysroot_add_sysroot() {
    local sysroot_path="$1"
    local sysroot_name="$2"
    
    if [[ -z "$sysroot_path" ]]; then
    _sysroot_print_error "Sysroot path is required"
        return 1
    fi
    
    if [[ ! -d "$sysroot_path" ]]; then
    _sysroot_print_error "Sysroot directory does not exist: $sysroot_path"
        return 1
    fi
    
    # Make path absolute
    sysroot_path=$(realpath "$sysroot_path")
    
    # Auto-generate name if not provided
    if [[ -z "$sysroot_name" ]]; then
        sysroot_name=$(basename "$sysroot_path")
    fi
    
    # Check if sysroot already exists
    if jq -e --arg path "$sysroot_path" '.sysroots[] | select(.path == $path)' "$SYSROOTS_CONFIG" > /dev/null 2>&1; then
    _sysroot_print_warning "Sysroot with path $sysroot_path already exists"
        return 1
    fi
    
    # Detect GCC version and target
    _sysroot_print_info "Detecting GCC version and target triplet..."
    local gcc_version=$(_sysroot_detect_gcc_version "$sysroot_path")
    local target_triplet=$(_sysroot_detect_target_triplet "$sysroot_path")
    
    # Create new sysroot entry
    local new_sysroot=$(jq -n \
        --arg name "$sysroot_name" \
        --arg path "$sysroot_path" \
        --arg version "$gcc_version" \
        --arg target "$target_triplet" \
        --arg added "$(date -Iseconds)" \
        '{
            name: $name,
            path: $path,
            gcc_version: $version,
            target_triplet: $target,
            added_date: $added
        }')
    
    # Add to configuration
    local temp_config=$(mktemp)
    jq --argjson sysroot "$new_sysroot" '.sysroots += [$sysroot]' "$SYSROOTS_CONFIG" > "$temp_config"
    mv "$temp_config" "$SYSROOTS_CONFIG"
    
    _sysroot_print_success "Added sysroot '$sysroot_name'"
    _sysroot_print_info "  Path: $sysroot_path"
    _sysroot_print_info "  GCC Version: $gcc_version"
    _sysroot_print_info "  Target: $target_triplet"
}

_sysroot_list_sysroots() {
    if [[ ! -f "$SYSROOTS_CONFIG" ]]; then
    _sysroot_print_info "No sysroots configured"
        return 0
    fi
    
    local count=$(jq '.sysroots | length' "$SYSROOTS_CONFIG")
    
    if [[ "$count" -eq 0 ]]; then
    _sysroot_print_info "No sysroots configured"
        return 0
    fi
    
    echo -e "${CYAN}Available Sysroots:${NC}"
    echo "===================="
    
    jq -r '.sysroots[] | 
        "\u001b[1;34m[\u001b[0m\(.name)\u001b[1;34m]\u001b[0m
         Path: \(.path)
         GCC Version: \(.gcc_version)
         Target: \(.target_triplet)
         Added: \(.added_date)
         "' "$SYSROOTS_CONFIG"
}

_sysroot_remove_sysroot() {
    local sysroot_name="$1"
    
    if [[ -z "$sysroot_name" ]]; then
    _sysroot_print_error "Sysroot name is required"
        return 1
    fi
    
    # Check if sysroot exists
    if ! jq -e --arg name "$sysroot_name" '.sysroots[] | select(.name == $name)' "$SYSROOTS_CONFIG" > /dev/null 2>&1; then
    _sysroot_print_error "Sysroot '$sysroot_name' not found"
        return 1
    fi
    
    # Remove sysroot
    local temp_config=$(mktemp)
    jq --arg name "$sysroot_name" '.sysroots = (.sysroots | map(select(.name != $name)))' "$SYSROOTS_CONFIG" > "$temp_config"
    mv "$temp_config" "$SYSROOTS_CONFIG"
    
    _sysroot_print_success "Removed sysroot '$sysroot_name'"
}

_sysroot_show_help() {
        echo -e "${CYAN}Sysroot Manager${NC} - GCC Version Management with Sysroots"
        echo
        echo -e "${YELLOW}USAGE:${NC}"
        echo -e "  source sysroot-manager.zsh"
        echo -e "  sysroot-manager [COMMAND] [OPTIONS]"
        echo
        echo -e "${YELLOW}COMMANDS:${NC}"
        echo -e "  ${GREEN}add${NC} <path> [name]        Add a new sysroot"
        echo -e "  ${GREEN}list${NC}                     List all configured sysroots"
        echo -e "  ${GREEN}select${NC} [name]            Select and activate a sysroot"
        echo -e "  ${GREEN}remove${NC} <name>            Remove a sysroot"
        echo -e "  ${GREEN}current${NC}                  Show currently active sysroot"
        echo -e "  ${GREEN}reset${NC}                    Reset environment to original state"
        echo -e "  ${GREEN}env${NC} <name>               Generate temporary environment script"
        echo -e "  ${GREEN}help${NC}                     Show this help message"
        echo
        echo -e "${YELLOW}EXAMPLES:${NC}"
        echo -e "  # Add a sysroot"
        echo -e "  sysroot-manager add /opt/gcc-arm-linux-gnueabihf arm-linux"
        echo
        echo -e "  # List all sysroots"
        echo -e "  sysroot-manager list"
        echo
        echo -e "  # Select a sysroot interactively"
        echo -e "  sysroot-manager select"
        echo
        echo -e "  # Select a specific sysroot"
        echo -e "  sysroot-manager select arm-linux"
        echo
        echo -e "  # Generate environment script"
        echo -e "  sysroot-manager env arm-linux > /tmp/arm-env.sh"
        echo -e "  source /tmp/arm-env.sh"
        echo
        echo -e "  # Reset environment"
        echo -e "  sysroot-manager reset"
        echo
        echo -e "${YELLOW}FILES:${NC}"
        echo -e "  ~/.sysroots.json         Sysroot configuration"
        echo -e "  ~/.current_sysroot       Currently active sysroot"
        echo -e "  ~/.path_backup           Original PATH backup"
}

sysroot-manager() {
    # Check dependencies
    if ! _sysroot_check_jq; then
        return 1
    fi
    
    # Initialize configuration
    _sysroot_init_sysroots_config
    
    local command="$1"
    if [[ $# -gt 0 ]]; then
        shift
    fi

    case "$command" in
        "add")
            _sysroot_add_sysroot "$1" "$2"
            ;;
        "list")
            _sysroot_list_sysroots
            ;;
        "select")
            select_sysroot "$1"
            ;;
        "remove")
            _sysroot_remove_sysroot "$1"
            ;;
        "current")
            show_current_sysroot
            ;;
        "reset")
            reset_environment
            ;;
        "env")
            local envfile="${1:-sysroot_manager.env}"
            echo "# Sourcable environment file generated by sysroot-manager" > "$envfile"
            for var in CC CXX AS AR LD NM STRIP OBJCOPY OBJDUMP RANLIB SIZE STRINGS READELF SYSROOT CROSS_COMPILE PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_PATH PKG_CONFIG_LIBDIR CFLAGS CXXFLAGS LDFLAGS; do
                eval "val=\"\${$var}\""
                [[ -n "$val" ]] && echo "export $var='$val'" >> "$envfile"
            done
            _sysroot_print_success "Environment file written to $envfile"
            ;;
        "help"|"--help"|"-h"|"")
            _sysroot_show_help
            ;;
        *)
            _sysroot_print_error "Unknown command: $command"
            _sysroot_show_help
            return 1
            ;;
    esac
}

# Function to show current sysroot
show_current_sysroot() {
    if [[ -f "$CURRENT_SYSROOT_FILE" ]]; then
        local current_name=$(cat "$CURRENT_SYSROOT_FILE")
        local sysroot_info=$(jq -r --arg name "$current_name" '.sysroots[] | select(.name == $name) | 
            "Name: \(.name)
Path: \(.path)
GCC Version: \(.gcc_version)
Target: \(.target_triplet)"' "$SYSROOTS_CONFIG" 2>/dev/null)
        
        if [[ -n "$sysroot_info" ]]; then
            echo -e "${CYAN}Currently Active Sysroot:${NC}"
            echo "$sysroot_info"
        else
            _sysroot_print_warning "Current sysroot '$current_name' not found in configuration"
        fi
    else
    _sysroot_print_info "No sysroot currently active"
    fi
}

# Function to backup current PATH
backup_path() {
    if [[ ! -f "$PATH_BACKUP_FILE" ]]; then
        echo "$PATH" > "$PATH_BACKUP_FILE"
    _sysroot_print_info "PATH backed up"
    fi
}

# Function to restore original PATH
restore_path() {
    if [[ -f "$PATH_BACKUP_FILE" ]]; then
        export PATH=$(cat "$PATH_BACKUP_FILE")
        _sysroot_print_info "PATH restored"
    else
        _sysroot_print_warning "No PATH backup found"
    fi
}

# Function to set environment variables for a sysroot
set_sysroot_environment() {
    local sysroot_name="$1"
    local sysroot_info=$(jq -r --arg name "$sysroot_name" '.sysroots[] | select(.name == $name)' "$SYSROOTS_CONFIG" 2>/dev/null)
    
    if [[ -z "$sysroot_info" ]]; then
    _sysroot_print_error "Sysroot '$sysroot_name' not found"
        return 1
    fi
    
    local sysroot_path=$(echo "$sysroot_info" | jq -r '.path')
    local target_triplet=$(echo "$sysroot_info" | jq -r '.target_triplet')
    
    # Backup current PATH
    backup_path
    
    # Find GCC and related tools
    local gcc_path=""
    local tool_prefix=""
    
    # Look for GCC in various locations
    for gcc_candidate in "$sysroot_path/bin/gcc" "$sysroot_path/usr/bin/gcc" "$sysroot_path/bin/"*-gcc; do
        if [[ -x "$gcc_candidate" ]]; then
            gcc_path="$gcc_candidate"
            # Extract tool prefix if it's a cross-compiler
            if [[ "$(basename "$gcc_candidate")" != "gcc" ]]; then
                tool_prefix=$(basename "$gcc_candidate" | sed 's/gcc$//')
            fi
            break
        fi
    done
    
    if [[ -z "$gcc_path" ]]; then
    _sysroot_print_error "No GCC found in sysroot"
        return 1
    fi
    
    local bin_dir=$(dirname "$gcc_path")
    
    # Update PATH to include sysroot binaries
    export PATH="$bin_dir:$PATH"
    
    # Set compiler environment variables
    export CC="$gcc_path"
    export CXX="${bin_dir}/${tool_prefix}g++"
    export AS="${bin_dir}/${tool_prefix}as"
    export AR="${bin_dir}/${tool_prefix}ar"
    export LD="${bin_dir}/${tool_prefix}ld"
    export NM="${bin_dir}/${tool_prefix}nm"
    export STRIP="${bin_dir}/${tool_prefix}strip"
    export OBJCOPY="${bin_dir}/${tool_prefix}objcopy"
    export OBJDUMP="${bin_dir}/${tool_prefix}objdump"
    export RANLIB="${bin_dir}/${tool_prefix}ranlib"
    export SIZE="${bin_dir}/${tool_prefix}size"
    export STRINGS="${bin_dir}/${tool_prefix}strings"
    export READELF="${bin_dir}/${tool_prefix}readelf"
    
    # Set sysroot-related variables
    export SYSROOT="$sysroot_path"
    export CROSS_COMPILE="$tool_prefix"
    
    # Set pkg-config environment variables
    export PKG_CONFIG_SYSROOT_DIR="$sysroot_path"
    export PKG_CONFIG_PATH="$sysroot_path/usr/lib/pkgconfig:$sysroot_path/usr/share/pkgconfig:$sysroot_path/lib/pkgconfig"
    export PKG_CONFIG_LIBDIR="$sysroot_path/usr/lib/pkgconfig:$sysroot_path/usr/share/pkgconfig"
    
    # Additional cross-compilation flags
    export CFLAGS="--sysroot=$sysroot_path"
    export CXXFLAGS="--sysroot=$sysroot_path"
    export LDFLAGS="--sysroot=$sysroot_path"
    
    # Save current sysroot
    echo "$sysroot_name" > "$CURRENT_SYSROOT_FILE"
    
    _sysroot_print_success "Environment set for sysroot '$sysroot_name'"
    _sysroot_print_info "  GCC: $gcc_path"
    _sysroot_print_info "  Sysroot: $sysroot_path"
    _sysroot_print_info "  Target: $target_triplet"
}

# Function to reset environment
reset_environment() {
    # Restore original PATH
    restore_path
    
    # Unset sysroot-related variables
    unset CC CXX AS AR LD NM STRIP OBJCOPY OBJDUMP RANLIB SIZE STRINGS READELF
    unset SYSROOT CROSS_COMPILE
    unset PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_PATH PKG_CONFIG_LIBDIR
    unset CFLAGS CXXFLAGS LDFLAGS
    
    # Remove current sysroot file
    [[ -f "$CURRENT_SYSROOT_FILE" ]] && rm "$CURRENT_SYSROOT_FILE"
    
    _sysroot_print_success "Environment reset to original state"
}

# Function to select sysroot interactively or by name
select_sysroot() {
    local sysroot_name="$1"
    
    # If name provided, use it directly
    if [[ -n "$sysroot_name" ]]; then
        set_sysroot_environment "$sysroot_name"
        return $?
    fi
    
    # Interactive selection
    local count=$(jq '.sysroots | length' "$SYSROOTS_CONFIG" 2>/dev/null || echo "0")
    
    if [[ "$count" -eq 0 ]]; then
    _sysroot_print_info "No sysroots configured. Use 'sysroot-manager add' to add one."
        return 0
    fi
    
    echo -e "${CYAN}Select a sysroot:${NC}"
    echo "=================="
    
    # Display numbered list
    local i=1
    local names=()
    while IFS= read -r line; do
        names+=("$line")
        local sysroot_info=$(jq -r --arg name "$line" '.sysroots[] | select(.name == $name)' "$SYSROOTS_CONFIG")
        local path=$(echo "$sysroot_info" | jq -r '.path')
        local version=$(echo "$sysroot_info" | jq -r '.gcc_version')
        local target=$(echo "$sysroot_info" | jq -r '.target_triplet')
        
        echo -e "${YELLOW}$i)${NC} ${GREEN}$line${NC}"
        echo "   Path: $path"
        echo "   GCC Version: $version"
        echo "   Target: $target"
        echo ""
        ((i++))
    done < <(jq -r '.sysroots[].name' "$SYSROOTS_CONFIG")
    
    echo -n "Enter selection (1-$count, or 'q' to quit): "
    read selection
    
    if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
    _sysroot_print_info "Selection cancelled"
        return 0
    fi
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le "$count" ]]; then
        local selected_name="${names[$((selection-1))]}"
        set_sysroot_environment "$selected_name"
    else
    _sysroot_print_error "Invalid selection: $selection"
        return 1
    fi
}

# Function to generate temporary environment script
generate_env_script() {
    local sysroot_name="$1"
    
    if [[ -z "$sysroot_name" ]]; then
    _sysroot_print_error "Sysroot name is required"
        return 1
    fi
    
    local sysroot_info=$(jq -r --arg name "$sysroot_name" '.sysroots[] | select(.name == $name)' "$SYSROOTS_CONFIG" 2>/dev/null)
    
    if [[ -z "$sysroot_info" ]]; then
    _sysroot_print_error "Sysroot '$sysroot_name' not found"
        return 1
    fi
    
    local sysroot_path=$(echo "$sysroot_info" | jq -r '.path')
    local target_triplet=$(echo "$sysroot_info" | jq -r '.target_triplet')
    
    # Find GCC and tools
    local gcc_path=""
    local tool_prefix=""
    
    for gcc_candidate in "$sysroot_path/bin/gcc" "$sysroot_path/usr/bin/gcc" "$sysroot_path/bin/"*-gcc; do
        if [[ -x "$gcc_candidate" ]]; then
            gcc_path="$gcc_candidate"
            if [[ "$(basename "$gcc_candidate")" != "gcc" ]]; then
                tool_prefix=$(basename "$gcc_candidate" | sed 's/gcc$//')
            fi
            break
        fi
    done
    
    if [[ -z "$gcc_path" ]]; then
    _sysroot_print_error "No GCC found in sysroot" >&2
        return 1
    fi
    
    local bin_dir=$(dirname "$gcc_path")
    
    # Generate the environment script
    cat << EOF
#!/usr/bin/env zsh
# Environment script for sysroot: $sysroot_name
# Generated on: $(date)

# Backup current PATH if not already backed up
if [[ -z "\$SYSROOT_PATH_BACKUP" ]]; then
    export SYSROOT_PATH_BACKUP="\$PATH"
fi

# Set PATH
export PATH="$bin_dir:\$SYSROOT_PATH_BACKUP"

# Compiler tools
export CC="$gcc_path"
export CXX="${bin_dir}/${tool_prefix}g++"
export AS="${bin_dir}/${tool_prefix}as"
export AR="${bin_dir}/${tool_prefix}ar"
export LD="${bin_dir}/${tool_prefix}ld"
export NM="${bin_dir}/${tool_prefix}nm"
export STRIP="${bin_dir}/${tool_prefix}strip"
export OBJCOPY="${bin_dir}/${tool_prefix}objcopy"
export OBJDUMP="${bin_dir}/${tool_prefix}objdump"
export RANLIB="${bin_dir}/${tool_prefix}ranlib"
export SIZE="${bin_dir}/${tool_prefix}size"
export STRINGS="${bin_dir}/${tool_prefix}strings"
export READELF="${bin_dir}/${tool_prefix}readelf"

# Sysroot variables
export SYSROOT="$sysroot_path"
export CROSS_COMPILE="$tool_prefix"

# PKG-config setup
export PKG_CONFIG_SYSROOT_DIR="$sysroot_path"
export PKG_CONFIG_PATH="$sysroot_path/usr/lib/pkgconfig:$sysroot_path/usr/share/pkgconfig:$sysroot_path/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$sysroot_path/usr/lib/pkgconfig:$sysroot_path/usr/share/pkgconfig"

# Compilation flags
export CFLAGS="--sysroot=$sysroot_path"
export CXXFLAGS="--sysroot=$sysroot_path"
export LDFLAGS="--sysroot=$sysroot_path"

# Function to reset environment
sysroot_reset() {
    if [[ -n "\$SYSROOT_PATH_BACKUP" ]]; then
        export PATH="\$SYSROOT_PATH_BACKUP"
        unset SYSROOT_PATH_BACKUP
    fi
    
    unset CC CXX AS AR LD NM STRIP OBJCOPY OBJDUMP RANLIB SIZE STRINGS READELF
    unset SYSROOT CROSS_COMPILE
    unset PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_PATH PKG_CONFIG_LIBDIR
    unset CFLAGS CXXFLAGS LDFLAGS
    unset -f sysroot_reset
    
    echo "Sysroot environment reset"
}

echo "Sysroot environment loaded: $sysroot_name"
echo "  GCC: $gcc_path"
echo "  Target: $target_triplet"
echo "  Use 'sysroot_reset' to restore original environment"
EOF
}

_sysroot_print_info "Sysroot Manager loaded. Type 'sysroot-manager help' for usage information."