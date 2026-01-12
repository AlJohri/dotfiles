# Dotfiles

GNU Stow-managed dotfiles with machine-specific targets.

## Setup

### Omarchy Linux (Framework 16)

```bash
git clone https://github.com/AlJohri/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make omarchy
```

### Ubuntu Desktop

```bash
git clone https://github.com/AlJohri/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make ubuntu
```

### macOS

```bash
git clone https://github.com/AlJohri/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make macos
```

### Remote/SSH Machines

```bash
git clone https://github.com/AlJohri/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make portable
```

## Make Targets

| Target | Description |
|--------|-------------|
| `make omarchy` | Full setup for Omarchy Linux (deps + stow) |
| `make ubuntu` | Full setup for Ubuntu desktop (deps + stow) |
| `make macos` | Full setup for macOS (deps + stow) |
| `make portable` | Minimal setup for SSH/remote machines (deps + stow) |
| `make stow-omarchy` | Stow only (no deps) |
| `make stow-ubuntu` | Stow only (no deps) |
| `make stow-portable` | Stow only (no deps) |

## Package Groups

| Target | Packages |
|--------|----------|
| `portable` | nvim, tmux, git, fish, starship, mise, delta |
| `ubuntu` | portable + bash, zsh, scripts, alacritty, ghostty, xdg, zed |
| `omarchy` | ubuntu + hypr, waybar, hyprmon, uwsm, wayvnc |

## What Gets Installed

The setup scripts install:
- **System packages:** stow, make, git, fish, tmux, neovim, bat, delta, jq, direnv, gh, fzf
- **Curl-based tools:** rust, mise, starship, uv
- **Omarchy only:** hyprland, waybar, hyprlock, hypridle, wayvnc, brightnessctl, pamixer
