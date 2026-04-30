#!/bin/sh
# OpenCode FreeBSD Installation Script
# 
# This script installs OpenCode on FreeBSD systems.
# It supports system-wide installation and user-local installation.
# It automatically detects where it can install, creates directories as needed,
# and configures PATH in shell profiles for user-local installations.
#
# Usage:
#   ./install.sh              # Auto-detect best location
#   ./install.sh --system     # System-wide installation (requires root)
#   ./install.sh --user       # User-local installation (~/.local)
#   ./install.sh --prefix /custom/path  # Custom prefix

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
PREFIX=""
INSTALL_TYPE="auto"
FORCE_SYSTEM=0

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --system)
            INSTALL_TYPE="system"
            shift
            ;;
        --user)
            INSTALL_TYPE="user"
            shift
            ;;
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --force-system)
            FORCE_SYSTEM=1
            shift
            ;;
        --help|-h)
            echo "OpenCode FreeBSD Installation Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --system        Install system-wide (requires root)"
            echo "  --user          Install to ~/.local"
            echo "  --prefix PATH   Custom installation prefix"
            echo "  --force-system  Force system-wide install (skip permission checks)"
            echo "  --help, -h      Show this help"
            echo ""
            echo "Without options, automatically detects the best installation"
            echo "location based on permissions and creates necessary directories."
            exit 0
            ;;
        *)
            echo "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get current user and check root
IS_ROOT=$(id -u 2>/dev/null || echo "1")
UNAME_S=$(uname -s 2>/dev/null || echo "Unknown")
HOME_DIR="${HOME:-$(eval echo ~$(whoami))}"

# Check if we're on FreeBSD
if [ "$UNAME_S" != "FreeBSD" ]; then
    echo "${YELLOW}Warning: This script is designed for FreeBSD.${NC}"
    echo "Detected OS: $UNAME_S"
    echo ""
fi

# Function to test if we can write to a directory
test_write() {
    dir="$1"
    if [ -d "$dir" ]; then
        # Test write permission
        touch "$dir/.test_write_$$" 2>/dev/null && rm -f "$dir/.test_write_$$" && return 0
        return 1
    else
        # Try to create it temporarily
        mkdir -p "$dir" && rmdir "$dir" 2>/dev/null && return 0
        return 1
    fi
}

# Function to ensure directory exists and is writable
ensure_dir() {
    dir="$1"
    if [ ! -d "$dir" ]; then
        echo "${CYAN}Creating directory: $dir${NC}"
        mkdir -p "$dir" || return 1
    fi
    test_write "$dir" || return 1
    return 0
}

# Function to detect user's shell
detect_shell() {
    # Check SHELL environment variable
    if [ -n "$SHELL" ]; then
        case "$SHELL" in
            */bash) echo "bash"; return ;;
            */zsh) echo "zsh"; return ;;
            */tcsh) echo "tcsh"; return ;;
            */csh) echo "csh"; return ;;
            */fish) echo "fish"; return ;;
            */sh) echo "sh"; return ;;
        esac
    fi
    
    # Check login shell from passwd
    USER_SHELL=$(getent passwd "$(whoami)" 2>/dev/null | cut -d: -f7 | xargs basename 2>/dev/null)
    case "$USER_SHELL" in
        bash) echo "bash"; return ;;
        zsh) echo "zsh"; return ;;
        tcsh) echo "tcsh"; return ;;
        csh) echo "csh"; return ;;
        fish) echo "fish"; return ;;
    esac
    
    # Fallback based on BINDIR
    if echo "$BINDIR" | grep -q "\.local\/bin"; then
        echo "bash"  # Default for most Linux/FreeBSD systems
    else
        echo "sh"
    fi
}

# Function to get the profile file for the shell
get_profile_file() {
    shell="$1"
    case "$shell" in
        bash) echo "$HOME_DIR/.bashrc" ;;
        zsh) echo "$HOME_DIR/.zshrc" ;;
        fish) echo "$HOME_DIR/.config/fish/config.fish" ;;
        tcsh|csh) echo "$HOME_DIR/.tcshrc" ;;
        *) echo "$HOME_DIR/.profile" ;;
    esac
}

# Function to check if PATH already contains the bindir
check_path_in_profile() {
    shell="$1"
    profile="$2"
    
    if [ ! -f "$profile" ]; then
        return 1  # Profile doesn't exist, needs to be created
    fi
    
    # Check if PATH already contains bindir in the profile
    case "$shell" in
        bash|zsh)
            if grep -qE "export PATH=.*[=:]$BINDIR[:\$]" "$profile" 2>/dev/null; then
                return 0  # PATH already configured
            fi
            if grep -qF "\"\$HOME/.local/bin\"" "$profile" 2>/dev/null; then
                return 0  # Generic ~/.local/bin already configured
            fi
            ;;
        fish)
            if grep -qF "fish_add_path" "$profile" 2>/dev/null && grep -qF "\$HOME/.local/bin" "$profile" 2>/dev/null; then
                return 0
            fi
            ;;
        tcsh|csh)
            if grep -qE "setenv PATH.*$BINDIR" "$profile" 2>/dev/null; then
                return 0
            fi
            ;;
    esac
    
    return 1  # PATH not found
}

# Function to add PATH to profile
add_path_to_profile() {
    shell="$1"
    profile="$2"
    
    # Create profile file if it doesn't exist
    if [ ! -f "$profile" ]; then
        touch "$profile" 2>/dev/null || return 1
        echo "# Created by OpenCode installer" > "$profile"
    fi
    
    case "$shell" in
        bash)
            echo "" >> "$profile"
            echo "# Added by OpenCode installer" >> "$profile"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$profile"
            echo "export OPENCODE_HOME=\"\$HOME/.local\"" >> "$profile"
            ;;
        zsh)
            echo "" >> "$profile"
            echo "# Added by OpenCode installer" >> "$profile"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$profile"
            echo "export OPENCODE_HOME=\"\$HOME/.local\"" >> "$profile"
            ;;
        fish)
            # Ensure config directory exists
            mkdir -p "$HOME_DIR/.config/fish" 2>/dev/null
            if [ ! -f "$profile" ]; then
                touch "$profile"
            fi
            echo "" >> "$profile"
            echo "# Added by OpenCode installer" >> "$profile"
            echo "fish_add_path \$HOME/.local/bin" >> "$profile"
            ;;
        tcsh|csh)
            echo "" >> "$profile"
            echo "# Added by OpenCode installer" >> "$profile"
            echo "setenv PATH \"\$HOME/.local/bin:\$PATH\"" >> "$profile"
            echo "setenv OPENCODE_HOME \"\$HOME/.local\"" >> "$profile"
            ;;
        *)
            echo "" >> "$profile"
            echo "# Added by OpenCode installer" >> "$profile"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$profile"
            ;;
    esac
    
    return 0
}

# Function to get the reload command for the shell
get_reload_command() {
    shell="$1"
    case "$shell" in
        bash) echo "source ~/.bashrc" ;;
        zsh) echo "source ~/.zshrc" ;;
        fish) echo "fish -l" ;;
        tcsh|csh) echo "source ~/.tcshrc" ;;
        *) echo "source ~/.profile" ;;
    esac
}

# Function to detect the best installation location
detect_location() {
    echo "${BLUE}Detecting installation location...${NC}"
    echo ""
    
    # Check system-wide locations first if root
    if [ "$IS_ROOT" = "0" ]; then
        echo "Running as root - checking system locations..."
        
        if test_write "/usr/local/bin" && test_write "/usr/local/lib" && test_write "/var/db"; then
            echo "${GREEN}✓ System-wide installation is available${NC}"
            return 0
        else
            echo "${YELLOW}! System-wide locations not writable, falling back to user-local${NC}"
            return 1
        fi
    else
        echo "Running as user - checking user-local locations..."
        
        # Check if ~/.local exists, if not we'll create it
        if [ ! -d "$HOME_DIR/.local" ]; then
            echo "${CYAN}~/.local does not exist, will create it${NC}"
            if mkdir -p "$HOME_DIR/.local" 2>/dev/null; then
                echo "${GREEN}✓ Created ~/.local directory${NC}"
            else
                echo "${RED}✗ Cannot create ~/.local directory${NC}"
                return 2
            fi
        fi
        
        # Check user-local paths
        if test_write "$HOME_DIR/.local/bin" && test_write "$HOME_DIR/.local/lib" && test_write "$HOME_DIR/.local/share"; then
            echo "${GREEN}✓ User-local installation is available${NC}"
            return 1
        else
            # Try to create the directories
            echo "${CYAN}Creating user-local directory structure...${NC}"
            for subdir in bin lib share; do
                if [ ! -d "$HOME_DIR/.local/$subdir" ]; then
                    mkdir -p "$HOME_DIR/.local/$subdir" 2>/dev/null || {
                        echo "${RED}✗ Cannot create $HOME_DIR/.local/$subdir${NC}"
                        return 2
                    }
                fi
            done
            
            if test_write "$HOME_DIR/.local/bin" && test_write "$HOME_DIR/.local/lib" && test_write "$HOME_DIR/.local/share"; then
                echo "${GREEN}✓ User-local installation is now available${NC}"
                return 1
            else
                echo "${RED}✗ Cannot write to user-local directories${NC}"
                return 2
            fi
        fi
    fi
}

# Determine prefix based on installation type and detected location
if [ -z "$PREFIX" ]; then
    if [ "$INSTALL_TYPE" = "system" ]; then
        PREFIX="/usr/local"
    elif [ "$INSTALL_TYPE" = "user" ]; then
        PREFIX="$HOME_DIR/.local"
    else
        # Auto-detect
        if [ "$IS_ROOT" = "0" ] && [ "$FORCE_SYSTEM" = "1" ]; then
            PREFIX="/usr/local"
        else
            # Run detection
            case $(detect_location) in
                0)
                    PREFIX="/usr/local"
                    ;;
                1)
                    PREFIX="$HOME_DIR/.local"
                    ;;
                2)
                    echo ""
                    echo "${RED}Error: Cannot determine a writable installation location.${NC}"
                    echo ""
                    echo "Please either:"
                    echo "  1. Run as root for system-wide installation"
                    echo "  2. Create ~/.local directory manually: mkdir -p ~/.local"
                    echo "  3. Use --prefix to specify a custom location"
                    exit 1
                    ;;
            esac
        fi
    fi
fi

# Paths
BINDIR="$PREFIX/bin"
LIBDIR="$PREFIX/lib/opencode"
DOCDIR="$PREFIX/share/doc/opencode"
STATEDIR=""
if [ "$IS_ROOT" = "0" ]; then
    STATEDIR="/var/db/opencode"
else
    STATEDIR="$HOME_DIR/.local/share/opencode"
fi

# Expand tilde in paths
BINDIR=$(eval echo "$BINDIR")
LIBDIR=$(eval echo "$LIBDIR")
DOCDIR=$(eval echo "$DOCDIR")
STATEDIR=$(eval echo "$STATEDIR")

echo "${BLUE}========================================${NC}"
echo "${BLUE}  OpenCode FreeBSD Installer${NC}"
echo "${BLUE}========================================${NC}"
echo ""
echo "Installation type: $INSTALL_TYPE"
echo "Prefix: $PREFIX"
echo ""
echo "Directories:"
echo "  Binary:   $BINDIR"
echo "  Libraries: $LIBDIR"
echo "  Documentation: $DOCDIR"
echo "  Data:     $STATEDIR"
echo ""

# Check if build exists
if [ ! -d "dist" ]; then
    echo "${YELLOW}No build directory found. Running build...${NC}"
    echo ""
    
    # Check if bun is available
    if ! command -v bun >/dev/null 2>&1; then
        echo "${RED}Error: bun is not installed.${NC}"
        echo ""
        echo "Please install bun first:"
        echo "  curl -fsSL https://bun.sh/install | sh"
        echo ""
        echo "Or via pkg:"
        echo "  pkg install bun"
        exit 1
    fi
    
    # Build
    echo "${GREEN}Building OpenCode...${NC}"
    bun run script/build.ts --baseline --single --skip-embed-web-ui
    echo ""
fi

# Find the FreeBSD build
BUILD_DIR=""
for dir in dist/opencode-freebsd-*; do
    if [ -d "$dir" ] && [ -f "$dir/bin/opencode" ]; then
        BUILD_DIR="$dir"
        break
    fi
done

if [ -z "$BUILD_DIR" ]; then
    echo "${RED}Error: No valid FreeBSD build found.${NC}"
    echo "Please run: bun run script/build.ts --baseline --single"
    exit 1
fi

echo "${GREEN}Found build: $BUILD_DIR${NC}"
echo ""

# Check if system-wide install is requested but we're not root
if [ "$INSTALL_TYPE" = "system" ] && [ "$IS_ROOT" != "0" ]; then
    echo "${RED}Error: System-wide installation requires root privileges.${NC}"
    echo ""
    echo "Please run with sudo:"
    echo "  sudo $0 --system"
    echo ""
    echo "Or install user-local:"
    echo "  $0 --user"
    exit 1
fi

# Create directories with permission checks
echo "${GREEN}Creating directories...${NC}"
echo ""

for dir_pair in "BIN:Binary:$BINDIR" "LIB:Libraries:$LIBDIR" "DOC:Documentation:$DOCDIR" "STATE:Data:$STATEDIR"; do
    key="${dir_pair%%:*}"
    label="${dir_pair#*:}"
    label="${label%%:*}"
    dir="${dir_pair##*:}"
    
    if ! ensure_dir "$dir"; then
        echo "${RED}Error: Cannot create or write to $dir ($label)${NC}"
        echo ""
        echo "Please check your permissions or use a different prefix:"
        echo "  $0 --prefix ~/.local"
        exit 1
    fi
    echo "${GREEN}✓${NC} $dir ($label)"
done

echo ""
echo "All directories ready."
echo ""

# Install binary
echo "${GREEN}Installing binary to $BINDIR...${NC}"
cp "$BUILD_DIR/bin/opencode" "$BINDIR/opencode"
chmod 755 "$BINDIR/opencode"
echo "Done."
echo ""

# Install documentation
echo "${GREEN}Installing documentation...${NC}"
if [ -f "README.md" ]; then
    cp README.md "$DOCDIR/" 2>/dev/null || true
fi
if [ -f "LICENSE" ]; then
    cp LICENSE "$DOCDIR/" 2>/dev/null || true
fi
echo "Done."
echo ""

# Verify installation
echo "${GREEN}Verifying installation...${NC}"
INSTALLED_VERSION=$("$BINDIR/opencode" --version 2>/dev/null || echo "unknown")
echo "Installed version: $INSTALLED_VERSION"
echo ""

echo "${GREEN}========================================${NC}"
echo "${GREEN}  Installation Complete!${NC}"
echo "${GREEN}========================================${NC}"
echo ""
echo "OpenCode has been installed to:"
echo "  $BINDIR/opencode"
echo ""

# Check if PATH includes the binary directory and configure shell profiles
if [ "$IS_ROOT" != "0" ]; then
    # User installation - check PATH and configure shell profile
    case ":$PATH:" in
        *":$BINDIR:"*)
            echo "${GREEN}✓${NC} OpenCode is in your PATH. Run 'opencode' to start."
            ;;
        *)
            # Detect user's shell
            USER_SHELL=$(detect_shell)
            PROFILE_FILE=$(get_profile_file "$USER_SHELL")
            
            echo "${YELLOW}Note: $BINDIR may not be in your PATH.${NC}"
            echo ""
            
            # Check if PATH is already configured in the profile
            if check_path_in_profile "$USER_SHELL" "$PROFILE_FILE"; then
                echo "${GREEN}✓${NC} PATH configuration found in $PROFILE_FILE"
                echo ""
                echo "Reload your shell configuration:"
                echo "  $(get_reload_command "$USER_SHELL")"
                echo ""
                echo "Or start a new terminal and run 'opencode'"
            else
                # Add PATH to profile
                echo "Adding $BINDIR to your shell profile ($PROFILE_FILE)..."
                echo ""
                
                if add_path_to_profile "$USER_SHELL" "$PROFILE_FILE"; then
                    echo "${GREEN}✓${NC} PATH configuration added to $PROFILE_FILE"
                    echo ""
                    echo "To apply the changes, run:"
                    echo "  ${CYAN}$(get_reload_command "$USER_SHELL")${NC}"
                    echo ""
                    echo "Or start a new terminal and run 'opencode'"
                    echo ""
                    echo "Alternatively, run directly with full path:"
                    echo "  $BINDIR/opencode"
                else
                    echo "${RED}✗${NC} Could not update shell profile automatically."
                    echo ""
                    echo "Please add this to your $PROFILE_FILE manually:"
                    echo ""
                    echo "  # For bash/zsh:"
                    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
                    echo ""
                    echo "  # For csh/tcsh:"
                    echo "  setenv PATH \"\$HOME/.local/bin:\$PATH\""
                    echo ""
                    echo "  # For fish:"
                    echo "  fish_add_path \$HOME/.local/bin"
                    echo ""
                fi
            fi
            ;;
    esac
else
    echo "Run 'opencode' to start."
fi

echo ""
echo "For more options, see:"
echo "  opencode --help"
echo ""
