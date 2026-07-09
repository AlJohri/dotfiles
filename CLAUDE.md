# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository using [GNU Stow](https://www.gnu.org/software/stow/) for symlink management. Each top-level directory represents a "stow package" that gets symlinked to the home directory.

## Commands

Setup targets (install deps + stow):
```bash
make omarchy    # Full Omarchy Linux (Hyprland/Wayland desktop)
make ubuntu     # Ubuntu desktop
make macos      # macOS
make portable   # Minimal for SSH/remote machines
```

Stow-only targets (no dependency installation):
```bash
make stow-omarchy
make stow-ubuntu
make stow-portable
```

Initialize submodules after cloning:
```bash
git submodule update --init
```

Restart waybar (reaps the whole cgroup, so orphaned module subprocesses don't
linger and pin anything; same thing `hyprctl reload` triggers via `waybar-refresh`):
```bash
systemctl --user stop 'app-Hyprland-waybar-*.scope'; setsid uwsm-app -- waybar
```

## Package Groups

- **CORE** (portable): nvim, tmux, git, fish, starship, mise, delta, claude
- **DESKTOP** (adds to core): bash, zsh, scripts, alacritty, ghostty, xdg, zed, applications
- **WAYLAND** (adds to desktop): hypr, waybar, uwsm, omarchy, elephant, imv, makima, wiremix

## Structure

Each package follows the stow convention where the directory structure mirrors the home directory:
- `fish/.config/fish/` → `~/.config/fish/`
- `nvim/.config/nvim/` → `~/.config/nvim/`
- `scripts/bin/` → `~/bin/`
- `delta/.local/share/delta/` → `~/.local/share/delta/` (special target)

Key packages:
- **fish**: Primary shell with custom functions in `functions/`, environment setup in `conf.d/`
- **nvim**: LazyVim-based Neovim config with custom plugins in `lua/plugins/`
- **tmux**: Uses TPM (Tmux Plugin Manager) with omarchy-tmux theme (git submodules)
- **hypr**: Hyprland window manager config (Linux/Wayland), modular configs split into `bindings.conf`, `monitors.conf`, `looknfeel.conf`, etc.
- **ghostty**: Terminal emulator config
- **waybar**: Status bar for Wayland compositors
- **xdg**: XDG config files: `mimeapps.list` (default apps), `user-dirs.*`, `autostart/`

## Hyprland Keybindings

When looking up a keybinding, check all three sources:
1. `hyprctl binds` — shows all active bindings at runtime (the ground truth)
2. `hypr/.config/hypr/bindings.conf` — user overrides/additions in this repo
3. `~/.local/share/omarchy/default/hypr/bindings/tiling-v2.conf` — upstream Omarchy base config

User bindings override the base config. If a binding isn't in the user file, check the base config.

## Notes

- **After adding, removing, or moving files within a stow package, re-stow it** so the new symlinks are created (e.g., `stow scripts` after adding a new script to `scripts/bin/`, or run the appropriate `make stow-*` target). Editing a file that's already symlinked does not require re-stowing — but a brand-new file is invisible from `~/` until you re-stow.
- **Stow conflict strategy (`STOW_FLAGS`):** `make stow-*` defaults to `--restow` — safe and idempotent; it re-creates symlinks and *fails loudly* if a real file has replaced one (drift) instead of silently absorbing it. The interactive first-install / post-`omarchy update` reconcile path (`scripts/bin/stow-review.sh`, which all `setup-*.sh` scripts call) overrides to `STOW_FLAGS=--adopt` **only when stdin is a TTY** — it pulls pre-existing real files into the repo and prompts per-file (keep/take/skip). A non-interactive run always uses safe `--restow`, so automated re-runs never adopt drift or hang on a prompt.
- App-specific scripts go in the relevant stow package's `bin/` folder (e.g., `hypr/bin/` for Hyprland scripts). Generic scripts go in the top-level `scripts/bin/` package.
- The `.envrc` sets `RIPGREP_CONFIG_PATH` to use `.ripgreprc`, which enables `--hidden` since most dotfiles are hidden
- Tmux plugins are git submodules under `tmux/.config/tmux/plugins/` (TPM and omarchy-tmux)
- Uses Omarchy theme system (`~/.config/omarchy/current/theme/`) across tmux, git, and nvim
- The delta package uses `--no-folding` with target `~/.local` (not home directory)
- The claude package is stowed with `--no-folding` so `~/.claude/skills/` stays a real directory. This lets skills managed outside this repo drop into `~/.claude/skills/` alongside the dotfiles ones without being absorbed into a folded symlink.
- Setup scripts are in `scripts/bin/` (e.g., `setup-omarchy.sh`, `setup-ubuntu.sh`, `setup-macos.sh`, `setup-portable.sh`)
- `windows.ps1` contains a PowerShell script for Windows environment setup
