#!/usr/bin/env zsh

# Sysroot Manager - Installation and Test Script
# This script demonstrates how to install and use the sysroot manager

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
INSTALL_DIR="$HOME/.local/bin"
SYSROOT_MANAGER_SCRIPT="$SCRIPT_DIR/sysroot-manager.zsh"

echo "=== Sysroot Manager Installation and Demo ==="
echo

# Check if the script exists
if [[ ! -f "$SYSROOT_MANAGER_SCRIPT" ]]; then
    echo "ERROR: sysroot-manager.zsh not found in $SCRIPT_DIR"
    exit 1
fi

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy the script to the installation directory
cp "$SYSROOT_MANAGER_SCRIPT" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/sysroot-manager.zsh"

echo "✓ Installed sysroot-manager.zsh to $INSTALL_DIR"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Adding $INSTALL_DIR to PATH in ~/.zshrc"
    echo "" >> ~/.zshrc
    echo "# Added by sysroot-manager installer" >> ~/.zshrc
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.zshrc
    echo "source \"$INSTALL_DIR/sysroot-manager.zsh\"" >> ~/.zshrc
    echo ""
    echo "✓ Added to ~/.zshrc. Please run 'source ~/.zshrc' or restart your shell."
else
    echo "✓ $INSTALL_DIR already in PATH"
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "To use the sysroot manager:"
echo "1. Source your ~/.zshrc or restart your shell"
echo "2. Run: source $INSTALL_DIR/sysroot-manager.zsh"
echo "3. Use: sysroot-manager help"
echo ""

# Source the script for immediate use
source "$INSTALL_DIR/sysroot-manager.zsh"

echo "=== Basic Usage Examples ==="
echo ""

# Test basic functionality
echo "Testing basic functionality..."
echo ""

# Show help
echo "1. Showing help:"
sysroot-manager help
echo ""

# List sysroots (should be empty initially)
echo "2. Listing sysroots (should be empty initially):"
sysroot-manager list
echo ""

# Demonstrate adding a sysroot (this will fail if no real sysroot exists, but shows the interface)
echo "3. Example of adding a sysroot:"
echo "   sysroot-manager add /opt/gcc-arm-linux-gnueabihf arm-linux"
echo "   (This would add a cross-compilation sysroot if it existed)"
echo ""

# Show how to generate an environment script
echo "4. Example of generating environment script:"
echo "   sysroot-manager env arm-linux > /tmp/arm-env.sh"
echo "   source /tmp/arm-env.sh"
echo ""

# Show current sysroot status
echo "5. Checking current sysroot:"
sysroot-manager current
echo ""

echo "=== Setup Instructions for Real Usage ==="
echo ""
echo "To use with real sysroots:"
echo ""
echo "1. Install a cross-compilation toolchain, for example:"
echo "   # For ARM:"
echo "   sudo apt-get install gcc-arm-linux-gnueabihf"
echo "   # Or download and extract a toolchain to /opt/"
echo ""
echo "2. Add the sysroot:"
echo "   sysroot-manager add /usr/arm-linux-gnueabihf arm-linux"
echo "   # or"
echo "   sysroot-manager add /opt/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu aarch64-linux"
echo ""
echo "3. Select the sysroot:"
echo "   sysroot-manager select"
echo "   # or"
echo "   sysroot-manager select arm-linux"
echo ""
echo "4. Verify the environment:"
echo "   echo \$CC"
echo "   \$CC --version"
echo "   echo \$PKG_CONFIG_SYSROOT_DIR"
echo ""
echo "5. Create a temporary environment script:"
echo "   sysroot-manager env arm-linux > /tmp/my-cross-env.sh"
echo "   # Later in a new shell:"
echo "   source /tmp/my-cross-env.sh"
echo ""
echo "6. Reset environment when done:"
echo "   sysroot-manager reset"
echo ""

echo "=== Configuration Files ==="
echo ""
echo "The sysroot manager uses these files:"
echo "  ~/.sysroots.json      - Stores sysroot configurations"
echo "  ~/.current_sysroot    - Currently active sysroot name"
echo "  ~/.path_backup        - Backup of original PATH"
echo ""

echo "=== Dependencies ==="
echo ""
echo "Required tools:"
echo "  - jq (for JSON processing)"
echo "  - realpath (for path resolution)"
echo ""
echo "Install jq if not available:"
echo "  # Ubuntu/Debian:"
echo "  sudo apt-get install jq"
echo "  # CentOS/RHEL:"
echo "  sudo yum install jq"
echo "  # macOS:"
echo "  brew install jq"
echo ""

echo "Installation and demo complete!"
echo "Run 'sysroot-manager help' to get started."

# === CFlag Manager Installation and Demo ===

CFLAG_MANAGER_SCRIPT="$SCRIPT_DIR/cflag_manager.zsh"

if [[ -f "$CFLAG_MANAGER_SCRIPT" ]]; then
    cp "$CFLAG_MANAGER_SCRIPT" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/cflag_manager.zsh"
    echo "✓ Installed cflag_manager.zsh to $INSTALL_DIR"

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo "Adding $INSTALL_DIR to PATH in ~/.zshrc"
        echo "source \"$INSTALL_DIR/cflag_manager.zsh\"" >> ~/.zshrc
        echo ""
        echo "✓ Added to ~/.zshrc. Please run 'source ~/.zshrc' or restart your shell."
    else
        echo "✓ $INSTALL_DIR already in PATH"
    fi

else
    echo "WARNING: cflag_manager.zsh not found in $SCRIPT_DIR. Skipping CFlag Manager installation."
fi