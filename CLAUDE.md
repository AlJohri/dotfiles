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

Restart waybar:
```bash
killall waybar; setsid uwsm-app -- waybar
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
- **hypr**: Hyprland window manager config (Linux/Wayland), modular configs split into `bindings.conf`, `monitors.conf`, `looknfeel.conf`, etc.
- **ghostty**: Terminal emulator config
- **waybar**: Status bar for Wayland compositors

Other packages: alacritty, bash, zsh, starship, git, wayvnc, hyprmon, delta, xdg

- **xdg**: XDG config files: `mimeapps.list` (default apps, query with `xdg-settings get default-web-browser`), `user-dirs.*` (XDG directories), `autostart/` (desktop entries)

## Notes

- The `.envrc` sets `RIPGREP_CONFIG_PATH` to use `.ripgreprc`, which enables `--hidden` since most dotfiles are hidden
- Tmux plugins are git submodules under `tmux/.config/tmux/plugins/` (TPM and omarchy-tmux)
- Uses Omarchy theme system (`~/.config/omarchy/current/theme/`) across tmux, git, and nvim
- The delta package uses `--no-folding` with target `~/.local` (not home directory)
- `windows.ps1` contains a PowerShell script for Windows environment setup
