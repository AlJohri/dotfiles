.PHONY: omarchy ubuntu macos portable stow-omarchy stow-ubuntu stow-portable

# Package groups
CORE = nvim tmux git fish starship mise delta
DESKTOP = bash zsh scripts alacritty ghostty xdg zed applications
WAYLAND = hypr waybar hyprmon uwsm wayvnc omarchy

# Full setup (deps + stow)
omarchy:
	./scripts/bin/setup-omarchy.sh

ubuntu:
	./scripts/bin/setup-ubuntu.sh

macos:
	./scripts/bin/setup-macos.sh

portable:
	./scripts/bin/setup-portable.sh

# Stow only (no deps)
stow-omarchy:
	stow --adopt -t ~ $(CORE) $(DESKTOP) $(WAYLAND)

stow-ubuntu:
	stow --adopt -t ~ $(CORE) $(DESKTOP)

stow-portable:
	stow --adopt -t ~ $(CORE)
