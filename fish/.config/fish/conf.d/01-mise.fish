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
#
# This is the ONLY place mise should be activated. The omarchy-fish package ships
# /usr/share/fish/vendor_conf.d/init.fish, which also runs `mise activate` (against
# the system /usr/bin/mise) before this file loads — a duplicate ~57ms hook-env on
# every shell. We suppress that vendor file via conf.d/init.fish (see the long
# comment there); do NOT add a second `mise activate` anywhere else.
set -l mise_bin (command -s mise)
test -x ~/.local/bin/mise; and set mise_bin ~/.local/bin/mise
$mise_bin activate fish | source
