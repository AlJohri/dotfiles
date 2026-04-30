# Initialize mise (tool version manager)
#
# Two mise binaries coexist:
# - /usr/bin/mise: installed via pacman as a dependency of omarchy-fish/omarchy-zsh
#   (can't be removed; updates lag behind omarchy's mirror)
# - ~/.local/bin/mise: installed via `curl https://mise.run | sh` in
#   setup-omarchy.sh for self-update support (`mise self-update`)
#
# conf.d scripts run before user PATH is fully set up, so `command -q mise`
# finds the older /usr/bin/mise first. We prefer ~/.local/bin/mise explicitly
# to avoid config parse errors when newer settings (e.g. github.use_git_credentials)
# aren't recognized by the older system binary.
set -l mise_bin (command -s mise)
test -x ~/.local/bin/mise; and set mise_bin ~/.local/bin/mise
$mise_bin activate fish | source
