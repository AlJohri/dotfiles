#!/usr/bin/env bash
set -euo pipefail

# Setup script for Omarchy Linux (Arch-based)

echo "==> Installing system packages..."
sudo pacman -S --noconfirm --needed \
    stow \
    make \
    git \
    fish \
    curl \
    unzip

echo "==> Installing Wayland/Hyprland packages..."
sudo pacman -S --noconfirm --needed \
    hyprland \
    waybar \
    hyprlock \
    hypridle \
    wayvnc \
    brightnessctl \
    pamixer

echo "==> Installing mise..."
if ! command -v mise &> /dev/null; then
    curl https://mise.jdx.dev/install.sh | sh
fi

echo "==> Installing mise tools..."
mise install

echo "==> Initializing git submodules..."
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"
git submodule update --init

echo "==> Stowing dotfiles..."
make stow-omarchy

echo "==> Setting up Chrome policy directory..."
"$DOTFILES_DIR/scripts/bin/setup-chrome.sh"

if command -v google-chrome-stable &> /dev/null; then
    echo "==> Setting Chrome as default browser..."
    xdg-settings set default-web-browser google-chrome.desktop
fi

echo "==> Done! Restart your shell or run: exec fish"
