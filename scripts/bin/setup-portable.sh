#!/usr/bin/env bash
set -euo pipefail

# Minimal setup script for SSH/remote machines
# Installs only essential tools for portable dotfiles

echo "==> Detecting package manager..."
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    sudo apt update
    sudo apt install -y stow make git fish tmux jq curl unzip build-essential

    # Ubuntu installs bat as batcat
    sudo apt install -y bat || true
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
    fi

    # Install latest neovim from GitHub
    echo "==> Installing latest Neovim..."
    NVIM_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.tag_name')
    curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    sudo pacman -Syu --noconfirm stow make git fish tmux neovim bat git-delta jq curl unzip
elif command -v brew &> /dev/null; then
    PKG_MANAGER="brew"
    brew install stow make git fish tmux neovim bat git-delta jq
else
    echo "Error: No supported package manager found (apt, pacman, brew)"
    exit 1
fi

echo "==> Installing mise..."
if ! command -v mise &> /dev/null; then
    curl https://mise.jdx.dev/install.sh | sh
fi

echo "==> Installing Starship..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

echo "==> Initializing git submodules..."
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || python3 -c "import os; print(os.path.realpath('${BASH_SOURCE[0]}'))")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"
git submodule update --init

echo "==> Stowing dotfiles..."
make stow-portable

echo "==> Done! Restart your shell or run: exec fish"
