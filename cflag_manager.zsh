#!/usr/bin/env zsh

# cflag_manager.zsh - GCC C/C++ Compiler Flag Management Tool
# Manages C and C++ standard flags, 32-bit compilation, and environment variables
# Author: GitHub Copilot
# Version: 1.0.0


CFLAGS_BACKUP_FILE="$HOME/.cflags_backup"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Internal color print functions
_cflag_print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
_cflag_print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
_cflag_print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
_cflag_print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

_cflag_show_help() {
    echo "${CYAN}cflag_manager - GCC C/C++ Compiler Flag Management Tool${NC}"
    echo ""
    echo "${YELLOW}USAGE:${NC}"
    echo "  source cflag_manager.zsh"
    echo "  cflag-manager [COMMAND] [OPTIONS]"
    echo ""
    echo "${YELLOW}COMMANDS:${NC}"
    echo "  ${GREEN}set${NC} <c-std> [c++-std]    Set C and/or C++ standard (e.g., c99 c++17)"
    echo "  ${GREEN}show${NC}                     Display current CFLAGS, CXXFLAGS, and ASFLAGS"
    echo "  ${GREEN}clear${NC}                    Clear all compiler flags"
    echo "  ${GREEN}reset${NC}                    Reset flags to original state"
    echo "  ${GREEN}list${NC}                     List all supported standards"
    echo "  ${GREEN}help${NC}                     Show this help message"
    echo ""
    echo "${YELLOW}FEATURES:${NC}"
    echo "  1. Validates standards against GCC-supported options"
    echo "  2. Adds -std=<standard> flag"
    echo "  3. Optionally adds -fpermissive flag"
    echo "  4. Optionally adds 32-bit compilation flags (-m32, -Wa,--32, -Wl,-m,elf_i386)"
    echo "  5. Exports CFLAGS, CXXFLAGS, and ASFLAGS environment variables"
    echo ""
    echo "${YELLOW}EXAMPLES:${NC}"
    echo "  # Set C11 standard with prompts for options"
    echo "  cflag-manager set c11"
    echo ""
    echo "  # Show current flags"
    echo "  cflag-manager show"
    echo ""
    echo "  # List supported standards"
    echo "  cflag-manager list"
    echo ""
    echo "  # Clear all flags"
    echo "  cflag-manager clear"
    echo ""
    echo "${YELLOW}FILES:${NC}"
    echo "  ~/.cflags_backup         Original CFLAGS backup"
}

# Function to get supported C standards from GCC
get_c_standards() {
    local standards=()
    # Query GCC for supported C standards
    for std in c89 c90 c99 c11 c17 c18 c2x gnu89 gnu90 gnu99 gnu11 gnu17 gnu18 gnu2x; do
        if gcc -std=$std -E -x c /dev/null >/dev/null 2>&1; then
            standards+=($std)
        fi
    done
    echo "${standards[@]}"
}

# Function to get supported C++ standards from GCC
get_cpp_standards() {
    local standards=()
    # Query GCC for supported C++ standards
    for std in c++98 c++03 c++11 c++14 c++17 c++20 c++23 c++2a c++2b gnu++98 gnu++03 gnu++11 gnu++14 gnu++17 gnu++20 gnu++23 gnu++2a gnu++2b; do
        if g++ -std=$std -E -x c++ /dev/null >/dev/null 2>&1; then
            standards+=($std)
        fi
    done
    echo "${standards[@]}"
}

# Function to validate if a standard is supported
validate_standard() {
    local requested_std="$1"
    local c_standards=($(get_c_standards))
    local cpp_standards=($(get_cpp_standards))
    
    # Check if it's a valid C standard
    for std in "${c_standards[@]}"; do
        if [[ "$std" == "$requested_std" ]]; then
            return 0
        fi
    done
    
    # Check if it's a valid C++ standard
    for std in "${cpp_standards[@]}"; do
        if [[ "$std" == "$requested_std" ]]; then
            return 0
        fi
    done
    
    return 1
}

_cflag_backup_flags() {
    if [[ ! -f "$CFLAGS_BACKUP_FILE" ]]; then
        cat > "$CFLAGS_BACKUP_FILE" << EOF
CFLAGS_BACKUP="${CFLAGS:-}"
CXXFLAGS_BACKUP="${CXXFLAGS:-}"
ASFLAGS_BACKUP="${ASFLAGS:-}"
EOF
        print_info "Compiler flags backed up"
    fi
}

_cflag_restore_flags() {
    if [[ -f "$CFLAGS_BACKUP_FILE" ]]; then
        source "$CFLAGS_BACKUP_FILE"
        export CFLAGS="$CFLAGS_BACKUP"
        export CXXFLAGS="$CXXFLAGS_BACKUP"
        export ASFLAGS="$ASFLAGS_BACKUP"
        print_info "Compiler flags restored"
    else
        print_warning "No backup found, clearing flags instead"
        clear_flags
    fi
}

_cflag_list_standards() {
    echo "${CYAN}Supported C standards:${NC}"
    local c_standards=($(get_c_standards))
    printf "  %s\n" "${c_standards[@]}"
    
    echo ""
    echo "${CYAN}Supported C++ standards:${NC}"
    local cpp_standards=($(get_cpp_standards))
    printf "  %s\n" "${cpp_standards[@]}"
}

_cflag_clear_flags() {
    unset CFLAGS
    unset CXXFLAGS
    unset ASFLAGS
    print_success "All compiler flags cleared"
}

_cflag_show_flags() {
    echo "${CYAN}Current compiler flags:${NC}"
    echo "CFLAGS: ${CFLAGS:-<not set>}"
    echo "CXXFLAGS: ${CXXFLAGS:-<not set>}"
    echo "ASFLAGS: ${ASFLAGS:-<not set>}"
}

_cflag_ask_fpermissive() {
    echo -n "Add -fpermissive flag? (y/N): "
    read response
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

_cflag_ask_32bit() {
    echo -n "Enable 32-bit compilation? (y/N): "
    read response
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

_cflag_set_flags() {
    local c_standard="$1"
    local cpp_standard="$2"
    local enable_32bit="$3"
    local enable_fpermissive="$4"

    backup_flags
    clear_flags >/dev/null

    local c_flags=""
    local cpp_flags=""
    local asm_flags=""
    local linker_flags=""

    if [[ -n "$c_standard" ]]; then
        c_flags="-std=$c_standard"
        if [[ "$enable_fpermissive" == "true" ]]; then
            c_flags="$c_flags -fpermissive"
        fi
        if [[ "$enable_32bit" == "true" ]]; then
            c_flags="$c_flags -m32 -Wa,--32 -Wl,-m,elf_i386"
            asm_flags="-Wa,--32"
        fi
        export CFLAGS="$c_flags"
    fi

    if [[ -n "$cpp_standard" ]]; then
        cpp_flags="-std=$cpp_standard"
        if [[ "$enable_fpermissive" == "true" ]]; then
            cpp_flags="$cpp_flags -fpermissive"
        fi
        if [[ "$enable_32bit" == "true" ]]; then
            cpp_flags="$cpp_flags -m32 -Wa,--32 -Wl,-m,elf_i386"
            asm_flags="-Wa,--32"
        fi
        export CXXFLAGS="$cpp_flags"
    fi

    export ASFLAGS="$asm_flags"

    print_success "Compiler flags set successfully!"
    show_flags
}

_cflag_set_standard() {
    local c_standard=""
    local cpp_standard=""

    # Parse arguments for C and C++ standards (order independent)
    for arg in "$@"; do
        if validate_standard "$arg"; then
            if [[ "$arg" == c++* || "$arg" == gnu++* ]]; then
                cpp_standard="$arg"
            elif [[ "$arg" == c*  || "$arg" == gnu* ]]; then
                c_standard="$arg"
            fi
        else
            print_error "'$arg' is not a supported standard"
            echo ""
            list_standards
            return 1
        fi
    done

    if [[ -z "$c_standard" && -z "$cpp_standard" ]]; then
        print_error "At least one valid C or C++ standard is required"
        list_standards
        return 1
    fi

    local enable_fpermissive="false"
    if ask_fpermissive; then
        enable_fpermissive="true"
    fi

    local enable_32bit="false"
    if ask_32bit; then
        enable_32bit="true"
    fi

    set_flags "$c_standard" "$cpp_standard" "$enable_32bit" "$enable_fpermissive"
}

cflag-manager() {
    local command="$1"
    if [[ $# -gt 0 ]]; then
        shift
    fi
    
    case "$command" in
        "set")
            _cflag_set_standard "$@"
            ;;
        "show")
            _cflag_show_flags
            ;;
        "clear")
            _cflag_clear_flags
            ;;
        "reset")
            _cflag_restore_flags
            ;;
        "list")
            _cflag_list_standards
            ;;
        "env")
            local envfile="${1:-cflag_manager.env}"
            echo "# Sourcable environment file generated by cflag-manager" > "$envfile"
            [[ -n "$CFLAGS" ]] && echo "export CFLAGS='$CFLAGS'" >> "$envfile"
            [[ -n "$CXXFLAGS" ]] && echo "export CXXFLAGS='$CXXFLAGS'" >> "$envfile"
            [[ -n "$ASFLAGS" ]] && echo "export ASFLAGS='$ASFLAGS'" >> "$envfile"
            _cflag_print_success "Environment file written to $envfile"
            ;;
        "help"|"--help"|"-h"|"")
            _cflag_show_help
            ;;
        *)
            _cflag_print_error "Unknown command: $command"
            _cflag_show_help
            return 1
            ;;
    esac
}

_cflag_main() {
    case "$1" in
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        "show")
            show_flags
            ;;
        "clear")
            clear_flags
            ;;
        "reset")
            restore_flags
            ;;
        "list")
            list_standards
            ;;
        *)
            local requested_std="$1"
            
            if [[ -n "$requested_std" ]]; then
                set_standard "$requested_std"
            else
                show_help
            fi
            ;;
    esac
}

_cflag_print_info "cflag-manager loaded. Type 'cflag-manager help' for usage information."