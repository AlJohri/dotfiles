# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository using [GNU Stow](https://www.gnu.org/software/stow/) for symlink management. Each top-level directory represents a "stow package" that gets symlinked to the home directory.

## Commands

Install/update all dotfiles:
```bash
make
```

This runs `stow --adopt --restow` on all packages, creating symlinks from `~/.config/` to the corresponding files in this repo.

Adopt an existing config into stow management:
```bash
adopt-config.sh ~/.config/someapp
```

This copies the config into the repo, removes the original, stows it, and updates the Makefile.

After cloning, initialize submodules:
```bash
git submodule update --init
```

## Structure

Each package follows the stow convention where the directory structure mirrors the home directory:
- `fish/.config/fish/` → `~/.config/fish/`
- `nvim/.config/nvim/` → `~/.config/nvim/`
- `tmux/.config/tmux/` → `~/.config/tmux/`
- `scripts/bin/` → `~/bin/`
- `delta/.local/share/delta/` → `~/.local/share/delta/` (special target)

Key packages:
- **fish**: Primary shell with custom functions in `functions/`, environment setup in `conf.d/`
- **nvim**: LazyVim-based Neovim config with custom plugins in `lua/plugins/`
- **tmux**: Uses TPM (Tmux Plugin Manager) with omarchy-tmux theme (git submodules)
- **hypr**: Hyprland window manager config (Linux/Wayland), modular configs in separate files

## Notes

- The `.envrc` enables `--hidden` for ripgrep since most dotfiles are hidden
- Tmux plugins are git submodules under `tmux/.config/tmux/plugins/`
- Uses Omarchy theme system (`~/.config/omarchy/current/theme/`) across tmux, git, and nvim
