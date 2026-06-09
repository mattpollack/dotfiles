# Zsh Configuration
# This file is sourced by both home-manager and standalone installations

# ============================================================================
# History Configuration
# ============================================================================
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history"

# Create history directory if it doesn't exist
mkdir -p "$(dirname "$HISTFILE")"

setopt SHARE_HISTORY           # Share history between all sessions
setopt HIST_IGNORE_DUPS        # Don't record duplicate entries
setopt HIST_IGNORE_SPACE       # Don't record commands starting with space
setopt HIST_EXPIRE_DUPS_FIRST  # Expire duplicates first when trimming

# ============================================================================
# Key Bindings
# ============================================================================
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

# ============================================================================
# Aliases
# ============================================================================
# Docker
alias dc='docker-compose'
alias de='docker-compose exec'
alias logs='docker-compose logs -f'
alias dcr='docker-compose stop && docker-compose build && docker-compose up -d'

# Editor
alias vim='nvim'

# Development
alias nr='npm run'
alias gp='git push origin HEAD'
alias python=python3
# alias pip=/usr/bin/pip3

# Navigation
alias ll='ls -la'
alias ..='cd ..'

# ============================================================================
# Functions
# ============================================================================
# Start HTTP server with IP display
serve() {
    echo "Local IP: $(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
    cd ~/Documents && python3 -m http.server
}

# ============================================================================
# Oh My Posh Prompt
# ============================================================================
if command -v oh-my-posh &> /dev/null; then
    if [ -f "$HOME/home-manager/dotfiles/config/oh-my-posh/custom.json" ]; then
        eval "$(oh-my-posh init zsh --config $HOME/home-manager/dotfiles/config/oh-my-posh/custom.json)"
    elif [ -f "$HOME/.config/oh-my-posh/custom.json" ]; then
        eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/custom.json)"
    fi
fi

# ============================================================================
# Path Configuration (sourced from environment or set here)
# ============================================================================
# These paths may be set by home-manager's envExtra or sourced separately
# Only add them if they're not already in PATH

add_to_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="$1:$PATH"
    fi
}

add_to_path "/opt/homebrew/bin"
add_to_path "/opt/homebrew/opt/python@3.14/libexec/bin"
add_to_path "$HOME/.pub-cache/bin"
add_to_path "/opt/homebrew/bin/nvim"
add_to_path "/usr/local/bin"
add_to_path "/Applications/Godot.app/Contents/MacOS"
add_to_path "/Applications/Blender.app/Contents/MacOS"
add_to_path "$HOME/.local/bin"
