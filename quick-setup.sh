#!/bin/bash
# Full macOS bootstrap - installs Homebrew, packages, and symlinks dotfiles

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$SCRIPT_DIR"

echo "Quick dotfiles setup"
echo "===================="
echo ""

# ============================================================================
# Homebrew
# ============================================================================

echo "Checking Homebrew..."
echo ""

if [[ "$(uname -m)" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

if ! command -v brew &>/dev/null; then
    echo "  Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($BREW_PREFIX/bin/brew shellenv)"
    echo ""
else
    echo "  Homebrew already installed"
    echo ""
fi

# ============================================================================
# Packages
# ============================================================================

echo "Trusting third-party Homebrew taps..."
echo ""
brew trust jetbrains/utils
echo ""

echo "Installing packages from Brewfile..."
echo ""
brew bundle --file="$SCRIPT_DIR/Brewfile"
echo ""

echo "Installing global npm packages..."
echo ""
npm install -g @mockoon/cli
echo ""

# ============================================================================
# Helper Functions
# ============================================================================

backup_if_exists() {
    local target=$1
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "  Backup: $target -> $backup"
        mv "$target" "$backup"
    elif [ -L "$target" ]; then
        rm "$target"
    fi
}

link() {
    local source=$1
    local target=$2

    if [ ! -e "$source" ]; then
        echo "  Skip: $source (not found)"
        return
    fi

    mkdir -p "$(dirname "$target")"
    backup_if_exists "$target"
    ln -sf "$source" "$target"
    echo "  Link: $target"
}

# ============================================================================
# Dynamic Dotfile Discovery and Linking
# ============================================================================

# Link files from dotfiles/home to ~/
echo "Linking home directory files..."
echo ""
if [ -d "$DOTFILES_DIR/home" ]; then
    for file in "$DOTFILES_DIR/home"/{.,}*; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        [ "$filename" = "." ] || [ "$filename" = ".." ] && continue
        echo "Processing: $filename"
        link "$file" "$HOME/$filename"
        echo ""
    done
fi

# Link directories from dotfiles/config to ~/.config
echo "Linking config directories..."
echo ""
if [ -d "$DOTFILES_DIR/config" ]; then
    for dir in "$DOTFILES_DIR/config"/*; do
        [ -d "$dir" ] || continue
        dirname=$(basename "$dir")
        echo "Processing: $dirname"
        link "$dir" "$HOME/.config/$dirname"
        echo ""
    done
fi

# ============================================================================
# Tmux Plugin Manager Setup
# ============================================================================

echo "Setting up Tmux Plugin Manager..."
echo ""

TMUX_PLUGIN_DIR="$HOME/.config/tmux/plugins"

# Install TPM if not present
if [ ! -d "$TMUX_PLUGIN_DIR/tpm" ]; then
    echo "  Installing TPM..."
    mkdir -p "$TMUX_PLUGIN_DIR"
    git clone https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_DIR/tpm"
else
    echo "  TPM already installed"
fi

# Install plugins via TPM
if [ -f "$TMUX_PLUGIN_DIR/tpm/bin/install_plugins" ]; then
    echo "  Installing tmux plugins..."
    "$TMUX_PLUGIN_DIR/tpm/bin/install_plugins"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Restart terminal or: source ~/.zshrc"
echo "  2. Start tmux or reload config: tmux source-file ~/.tmux.conf"
echo "  3. In Neovim, run: :Lazy sync"
echo ""
