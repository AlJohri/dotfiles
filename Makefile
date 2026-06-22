.PHONY: omarchy ubuntu macos portable stow-core stow-omarchy stow-ubuntu stow-macos stow-portable

# Package groups
CORE = nvim tmux git fish mise delta claude-history zsh
DESKTOP = bash scripts alacritty ghostty xdg zed applications code-server
MACOS = yabai skhd
WAYLAND = hypr waybar uwsm omarchy wireplumber elephant imv makima wiremix

# Full setup (deps + stow)
omarchy:
	./scripts/bin/setup-omarchy.sh

ubuntu:
	./scripts/bin/setup-ubuntu.sh

macos:
	./scripts/bin/setup-macos.sh

portable:
	./scripts/bin/setup-portable.sh

# Stow only (no deps).
# claude and starship are part of core but use --no-folding so ~/.claude/skills/
# and ~/bin stay real directories. starship is the only core package with a bin/,
# so without --no-folding stow folds ~/bin into a symlink to starship/bin, and
# anything later added to ~/bin (or stowing the scripts package) lands inside the
# starship package. claude keeps room for externally-managed skills.
stow-core:
	stow --adopt -t ~ $(CORE)
	stow --adopt --no-folding -t ~ claude starship

stow-omarchy: stow-core
	stow --adopt -t ~ $(DESKTOP) $(WAYLAND)

stow-ubuntu: stow-core
	stow --adopt -t ~ $(DESKTOP)

stow-macos: stow-core
	stow --adopt -t ~ $(DESKTOP) $(MACOS)

stow-portable: stow-core
