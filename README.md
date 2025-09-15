# Sysroot Manager

A comprehensive zsh script for managing GCC versions with sysroots, designed for cross-compilation and development environment management.

## Features

- **Sysroot Management**: Add, list, select, and remove GCC sysroots
- **Automatic Detection**: Automatically detects GCC version and target triplet
- **Environment Control**: Sets up complete cross-compilation environment
- **PATH Management**: Safely modifies and restores PATH
- **PKG-Config Integration**: Configures pkg-config for cross-compilation
- **Temporary Scripts**: Generate reusable environment scripts
- **Interactive Selection**: User-friendly sysroot selection interface
- **Configuration Storage**: Persistent storage in JSON format

## Installation

### Quick Install

```bash
# Download or copy the sysroot-manager.zsh script
chmod +x install-sysroot-manager.zsh
./install-sysroot-manager.zsh
```

### Manual Install

```bash
# Copy to a directory in your PATH
cp sysroot-manager.zsh ~/.local/bin/
chmod +x ~/.local/bin/sysroot-manager.zsh

# Add to your ~/.zshrc
echo 'source ~/.local/bin/sysroot-manager.zsh' >> ~/.zshrc
source ~/.zshrc
```

## Dependencies

- **jq**: JSON processor (required)
- **realpath**: Path resolution utility (usually pre-installed)

Install jq:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq

# macOS
brew install jq
```

## Usage

### Basic Commands

```bash
# Show help
sysroot-manager help

# Add a sysroot
sysroot-manager add <path> [name]

# List all sysroots
sysroot-manager list

# Select a sysroot (interactive)
sysroot-manager select

# Select a specific sysroot
sysroot-manager select <name>

# Show current active sysroot
sysroot-manager current

# Reset environment to original state
sysroot-manager reset

# Generate temporary environment script
sysroot-manager env <name>

# Remove a sysroot
sysroot-manager remove <name>
```

### Example Workflow

1. **Install a cross-compilation toolchain**:
   ```bash
   # Example: ARM cross-compiler
   sudo apt-get install gcc-arm-linux-gnueabihf
   
   # Or download a toolchain to /opt/
   wget https://example.com/gcc-arm-10.3-toolchain.tar.xz
   sudo tar -xf gcc-arm-10.3-toolchain.tar.xz -C /opt/
   ```

2. **Add the sysroot**:
   ```bash
   # System-installed toolchain
   sysroot-manager add /usr/arm-linux-gnueabihf arm-linux
   
   # Custom toolchain
   sysroot-manager add /opt/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu aarch64-linux
   ```

3. **List available sysroots**:
   ```bash
   sysroot-manager list
   ```

4. **Select and activate a sysroot**:
   ```bash
   # Interactive selection
   sysroot-manager select
   
   # Direct selection
   sysroot-manager select arm-linux
   ```

5. **Verify the environment**:
   ```bash
   echo $CC
   $CC --version
   echo $PKG_CONFIG_SYSROOT_DIR
   ```

6. **Use for compilation**:
   ```bash
   # The environment is now set up for cross-compilation
   make CC=$CC
   
   # Or use with autotools
   ./configure --host=arm-linux-gnueabihf
   make
   ```

7. **Create a reusable environment script**:
   ```bash
   sysroot-manager env arm-linux > /tmp/arm-env.sh
   
   # Later, in a new shell:
   source /tmp/arm-env.sh
   ```

8. **Reset when done**:
   ```bash
   sysroot-manager reset
   ```

## Environment Variables Set

When a sysroot is activated, the following environment variables are set:

### Compiler Tools
- `CC`: C compiler path
- `CXX`: C++ compiler path
- `AS`: Assembler path
- `AR`: Archive tool path
- `LD`: Linker path
- `NM`: Symbol table tool path
- `STRIP`: Strip utility path
- `OBJCOPY`: Object copy utility path
- `OBJDUMP`: Object dump utility path
- `RANLIB`: Archive index generator path
- `SIZE`: Size utility path
- `STRINGS`: Strings utility path
- `READELF`: ELF file analyzer path

### Cross-Compilation Variables
- `SYSROOT`: Sysroot directory path
- `CROSS_COMPILE`: Cross-compilation prefix
- `CFLAGS`: C compilation flags with sysroot
- `CXXFLAGS`: C++ compilation flags with sysroot
- `LDFLAGS`: Linker flags with sysroot

### PKG-Config Variables
- `PKG_CONFIG_SYSROOT_DIR`: PKG-config sysroot directory
- `PKG_CONFIG_PATH`: PKG-config search paths
- `PKG_CONFIG_LIBDIR`: PKG-config library directories

### PATH
- Sysroot binary directories are prepended to PATH
- Original PATH is backed up and can be restored

## Configuration Files

- `~/.sysroots.json`: Stores sysroot configurations
- `~/.current_sysroot`: Currently active sysroot name
- `~/.path_backup`: Backup of original PATH

### Sysroot Configuration Format

```json
{
  "sysroots": [
    {
      "name": "arm-linux",
      "path": "/usr/arm-linux-gnueabihf",
      "gcc_version": "9.4.0",
      "target_triplet": "arm-linux-gnueabihf",
      "added_date": "2025-09-15T10:30:00+00:00"
    }
  ]
}
```

## Advanced Usage

### Custom Toolchain Setup

```bash
# Download and extract a custom toolchain
mkdir -p ~/toolchains
cd ~/toolchains
wget https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz
tar -xf gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz

# Add to sysroot manager
sysroot-manager add ~/toolchains/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu aarch64-gnu

# Select it
sysroot-manager select aarch64-gnu
```

### Automated Environment Scripts

```bash
# Create environment scripts for different projects
sysroot-manager env arm-linux > ~/projects/embedded-project/arm-env.sh
sysroot-manager env aarch64-gnu > ~/projects/server-project/aarch64-env.sh

# Use in your build scripts
#!/bin/bash
source ~/projects/embedded-project/arm-env.sh
make -C ~/projects/embedded-project/
```

### Integration with Build Systems

#### CMake
```bash
sysroot-manager select arm-linux
cmake -DCMAKE_C_COMPILER=$CC \
      -DCMAKE_CXX_COMPILER=$CXX \
      -DCMAKE_SYSROOT=$SYSROOT \
      ..
```

#### Autotools
```bash
sysroot-manager select arm-linux
./configure --host=$(basename $CC | sed 's/-gcc$//')
```

#### Meson
```bash
sysroot-manager select arm-linux
meson setup builddir --cross-file cross-compile.txt
```

## Troubleshooting

### Common Issues

1. **jq not found**:
   ```bash
   sudo apt-get install jq  # Ubuntu/Debian
   sudo yum install jq      # CentOS/RHEL
   brew install jq          # macOS
   ```

2. **GCC not detected in sysroot**:
   - Ensure the sysroot contains GCC in `bin/` or `usr/bin/`
   - Check that the GCC binary is executable
   - Verify the sysroot path is correct

3. **Environment not working**:
   ```bash
   # Check current environment
   sysroot-manager current
   
   # Reset and try again
   sysroot-manager reset
   sysroot-manager select <sysroot-name>
   ```

4. **PKG-config not finding libraries**:
   - Ensure the sysroot contains `.pc` files in `lib/pkgconfig/` or `usr/lib/pkgconfig/`
   - Check `PKG_CONFIG_PATH` and `PKG_CONFIG_SYSROOT_DIR` variables

### Debug Information

```bash
# Check environment variables
env | grep -E "(CC|SYSROOT|PKG_CONFIG)"

# Verify compiler
$CC --version
$CC -print-sysroot

# Check PKG-config
pkg-config --list-all | head -5
```

## Contributing

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This script is provided as-is under the MIT License. See LICENSE file for details.

## Author

Created by GitHub Copilot for efficient GCC sysroot management.

# CFlag Manager

A zsh script for managing GCC C and C++ compiler flags, designed to work alongside sysroot-manager for flexible build environment control.

## Features

- **C/C++ Standard Management**: Set C and/or C++ standard flags independently
- **Optional Flags**: Prompt for -fpermissive and 32-bit compilation options
- **Environment Control**: Exports CFLAGS, CXXFLAGS, and ASFLAGS as needed
- **Backup/Restore**: Backup and restore original flag values
- **Interactive Prompts**: User-friendly flag selection
- **Sourcing Support**: Can be sourced for persistent environment changes

## Installation

### Quick Install

```bash
# Download or copy the cflag_manager.zsh script
chmod +x cflag_manager.zsh
```

### Manual Install

```bash
# Copy to a directory in your PATH
cp cflag_manager.zsh ~/.local/bin/
chmod +x ~/.local/bin/cflag_manager.zsh

# Add to your ~/.zshrc
echo 'source ~/.local/bin/cflag_manager.zsh' >> ~/.zshrc
source ~/.zshrc
```

## Usage

### Basic Commands

```bash
# Show help
cflag-manager help

# Set C and/or C++ standard
cflag-manager set c11 c++17

# Show current flags
cflag-manager show

# List supported standards
cflag-manager list

# Clear all flags
cflag-manager clear

# Restore original flags
cflag-manager reset
```

### Example Workflow

1. **Set C and C++ standards**:
   ```bash
   cflag-manager set c99 c++20
   ```
2. **Show current flags**:
   ```bash
   cflag-manager show
   ```
3. **Clear flags**:
   ```bash
   cflag-manager clear
   ```
4. **Restore original flags**:
   ```bash
   cflag-manager reset
   ```

## Environment Variables Set

- `CFLAGS`: C compiler flags (if C standard given)
- `CXXFLAGS`: C++ compiler flags (if C++ standard given)
- `ASFLAGS`: Assembler flags (if 32-bit enabled)

## Configuration Files

- `~/.cflags_backup`: Stores backup of original flags

## Integration

`cflag_manager.zsh` can be used alongside `sysroot-manager.zsh` for complete control of cross-compilation and build flags. Source both scripts in your shell or add them to your `.zshrc` for persistent usage.