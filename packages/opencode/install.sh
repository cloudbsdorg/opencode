#!/bin/sh
# OpenCode FreeBSD Installation Script
# 
# FreeBSD-only installation - no Bun dependency required.
# The built binary uses Node.js.
#
# Usage:
#   ./install.sh              # Auto-detect best location
#   ./install.sh --system    # System-wide (requires sudo)
#   ./install.sh --user      # User-local (~/.local)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PREFIX=""
INSTALL_TYPE="auto"

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --system) INSTALL_TYPE="system"; shift ;;
        --user) INSTALL_TYPE="user"; shift ;;
        --prefix) PREFIX="$2"; shift 2 ;;
        --help|-h)
            echo "OpenCode FreeBSD Installer"
            echo "Usage: $0 [--system|--user|--prefix PATH]"
            echo ""
            echo "  --system   Install to /usr/local (requires sudo)"
            echo "  --user     Install to ~/.local"
            echo "  --prefix   Custom prefix"
            exit 0 ;;
        *) echo "${RED}Unknown: $1${NC}"; exit 1 ;;
    esac
done

IS_ROOT=$(id -u 2>/dev/null || echo "1")
HOME_DIR="${HOME:-$(eval echo ~$(whoami))}"

# Detect installation prefix
if [ -z "$PREFIX" ]; then
    case "$INSTALL_TYPE" in
        system)
            PREFIX="/usr/local"
            ;;
        user)
            PREFIX="$HOME_DIR/.local"
            ;;
        auto)
            if [ "$IS_ROOT" = "0" ] && [ -w "/usr/local/bin" ]; then
                PREFIX="/usr/local"
                INSTALL_TYPE="system"
            else
                PREFIX="$HOME_DIR/.local"
                INSTALL_TYPE="user"
            fi
            ;;
    esac
fi

BINDIR="$PREFIX/bin"
LIBDIR="$PREFIX/lib/opencode"
DOCDIR="$PREFIX/share/doc/opencode"
STATEDIR="$HOME_DIR/.local/share/opencode"

echo "${BLUE}OpenCode FreeBSD Installer${NC}"
echo "Installation type: $INSTALL_TYPE"
echo "Prefix: $PREFIX"
echo ""

# Check for build
if [ ! -f "dist/opencode-freebsd-x64/bin/opencode" ]; then
    echo "${YELLOW}No build found. Build first with: bun run script/build.ts --single${NC}"
    echo ""
    echo "Or download a pre-built release from:"
    echo "  https://github.com/anomalyco/opencode/releases"
    exit 1
fi

# Create directories
echo "Creating directories..."
for dir in "$BINDIR" "$LIBDIR" "$DOCDIR"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || { echo "${RED}Failed to create $dir${NC}"; exit 1; }
    fi
done
mkdir -p "$STATEDIR" 2>/dev/null || true
echo ""

# Install binary
echo "Installing to $BINDIR..."
cp dist/opencode-freebsd-x64/bin/opencode "$BINDIR/opencode"
chmod 755 "$BINDIR/opencode"

# Install docs
cp README.md LICENSE "$DOCDIR/" 2>/dev/null || true
echo ""

# Verify
INSTALLED_VERSION=$("$BINDIR/opencode" --version 2>/dev/null || echo "unknown")
echo "${GREEN}✓ Installed: $INSTALLED_VERSION${NC}"
echo ""
echo "Binary: $BINDIR/opencode"
echo ""

# Configure PATH for user-local install
if [ "$INSTALL_TYPE" = "user" ]; then
    SHELL_NAME=$(basename "${SHELL:-bash}" 2>/dev/null || echo "bash")
    case "$SHELL_NAME" in
        bash) PROFILE="$HOME_DIR/.bashrc" ;;
        zsh) PROFILE="$HOME_DIR/.zshrc" ;;
        fish) PROFILE="$HOME_DIR/.config/fish/config.fish" ;;
        tcsh|csh) PROFILE="$HOME_DIR/.tcshrc" ;;
        *) PROFILE="$HOME_DIR/.profile" ;;
    esac
    
    echo "Configuring PATH in $PROFILE..."
    
    if [ -f "$PROFILE" ] && grep -q "\.local/bin" "$PROFILE" 2>/dev/null; then
        echo "${GREEN}✓ PATH already configured${NC}"
    else
        echo "" >> "$PROFILE"
        echo "# Added by OpenCode installer" >> "$PROFILE"
        case "$SHELL_NAME" in
            fish)
                echo "fish_add_path \$HOME/.local/bin" >> "$PROFILE" ;;
            tcsh|csh)
                echo 'setenv PATH "$HOME/.local/bin:$PATH"' >> "$PROFILE" ;;
            *)
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE" ;;
        esac
        echo "${GREEN}✓ PATH added${NC}"
    fi
    echo ""
    echo "Reload shell: source $PROFILE"
fi

echo "${GREEN}Done!${NC}"
