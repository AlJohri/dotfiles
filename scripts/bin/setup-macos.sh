#!/usr/bin/env bash
set -euo pipefail

# Setup script for macOS

echo "==> Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "==> Installing system packages..."
brew install \
    stow \
    make \
    git \
    fish \
    tmux \
    neovim \
    bat \
    git-delta \
    jq \
    direnv \
    gh \
    fzf

echo "==> Installing Rust..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
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

echo "==> Initializing git submodules..."
# macOS doesn't have readlink -f, use Python instead
REAL_SCRIPT="$(python3 -c "import os; print(os.path.realpath('${BASH_SOURCE[0]}'))")"
DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$REAL_SCRIPT")")")"
cd "$DOTFILES_DIR"
git submodule update --init

echo "==> Stowing dotfiles..."
make stow-portable

echo "==> Done! Restart your shell or run: exec fish"
