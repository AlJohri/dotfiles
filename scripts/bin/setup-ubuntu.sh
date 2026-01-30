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

echo "==> Stowing dotfiles..."
make stow-ubuntu

echo "==> Done! Restart your shell or run: exec fish"
