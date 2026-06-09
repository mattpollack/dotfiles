# dotfiles

Portable dotfiles for macOS. Used standalone via `quick-setup.sh`, or as a git submodule inside the private `home-manager` repo for Nix-managed hosts.

## Structure

```
home/       → symlinked to ~/           (.zshrc, .tmux.conf)
config/     → symlinked to ~/.config/   (nvim/, tmux/, wezterm/, git/, ...)
```

## Quick setup (macOS, no Nix)

```bash
# Install packages
brew bundle

# Symlink dotfiles and install tmux plugins
./quick-setup.sh
```

After running: `source ~/.zshrc`, then in Neovim `:Lazy sync`.

## Nix users

This repo is consumed as a submodule in the private `home-manager` repo. Nix modules reference files here via relative paths — no duplication. Tmux plugins are nix-managed there instead of TPM.
