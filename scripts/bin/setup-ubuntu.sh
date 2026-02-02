#!/usr/bin/env bash
set -euo pipefail

# Setup script for Ubuntu/Debian systems

echo "==> Installing system packages..."
sudo apt update
sudo apt install -y \
    stow \
    make \
    git \
    fish \
    curl \
    unzip \
    build-essential

echo "==> Installing mise..."
if ! command -v mise &> /dev/null; then
    curl https://mise.jdx.dev/install.sh | sh
fi

echo "==> Installing mise tools..."
mise install

echo "==> Installing CaskaydiaMono Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -d "$FONT_DIR/CaskaydiaMono" ]; then
    mkdir -p "$FONT_DIR/CaskaydiaMono"
    NERD_FONT_VERSION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r '.tag_name')
    curl -fLo /tmp/CascadiaMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/CascadiaMono.zip"
    unzip -o /tmp/CascadiaMono.zip -d "$FONT_DIR/CaskaydiaMono"
    rm /tmp/CascadiaMono.zip
    fc-cache -fv
else
    echo "    CaskaydiaMono Nerd Font already installed"
fi

echo "==> Initializing git submodules..."
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"
git submodule update --init

echo "==> Creating nvim theme config (catppuccin fallback)..."
mkdir -p ~/.config/nvim/lua/plugins
cat > ~/.config/nvim/lua/plugins/theme.lua << 'THEME'
-- Conditional theme loader: uses omarchy theme if available, falls back to catppuccin
local omarchy_theme = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")

if vim.fn.filereadable(omarchy_theme) == 1 then
  -- Load omarchy theme
  return dofile(omarchy_theme)
else
  -- Fallback to catppuccin
  return {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      lazy = false,
      priority = 1000,
      opts = {
        flavour = "mocha",
      },
    },
    {
      "LazyVim/LazyVim",
      opts = {
        colorscheme = "catppuccin",
      },
    },
  }
end
THEME

echo "==> Stowing dotfiles..."
make stow-ubuntu

echo "==> Done! Restart your shell or run: exec fish"
