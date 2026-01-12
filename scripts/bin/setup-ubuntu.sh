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
    tmux \
    bat \
    git-delta \
    jq \
    direnv \
    gh \
    fzf \
    curl \
    unzip \
    build-essential

# Ubuntu installs bat as batcat, create symlink
if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
fi

echo "==> Installing latest Neovim..."
NVIM_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.tag_name')
CURRENT_NVIM_VERSION=""
if command -v nvim &> /dev/null; then
    CURRENT_NVIM_VERSION=$(nvim --version | head -1 | grep -oP 'v[\d.]+')
fi
if [[ "$CURRENT_NVIM_VERSION" != "$NVIM_VERSION" ]]; then
    echo "    Upgrading Neovim from ${CURRENT_NVIM_VERSION:-none} to ${NVIM_VERSION}..."
    curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
else
    echo "    Neovim ${NVIM_VERSION} already installed"
fi

echo "==> Installing Rust..."
if [[ ! -d "$HOME/.rustup" ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "    Rust already installed"
fi

echo "==> Installing mise..."
if ! command -v mise &> /dev/null; then
    curl https://mise.jdx.dev/install.sh | sh
fi

echo "==> Installing Starship..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

echo "==> Installing uv..."
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

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
