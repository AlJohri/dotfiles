# Shadows the omarchy-fish vendor init.fish by filename so fish skips it entirely
# (same-named file in ~/.config/fish/conf.d outranks /usr/share/fish/vendor_conf.d).
# No body needed — existing is enough. Upstream:
# https://github.com/omacom-io/omarchy-fish/blob/master/conf.d/init.fish
#
# Why skip it: vendor conf.d loads before ours and re-runs mise/zoxide/starship
# activation (our conf.d/{01-mise,zoxide,starship}.fish already do these -> double
# init, ~+110ms, and it activates system mise not our ~/.local/bin/mise) plus
# fish_vi_key_bindings (config.fish wants default bindings). A guard in our files
# can't undo it — they run second — so we stop the vendor file from running at all.
#
# DELIBERATE DEVIATION: the vendor file also runs `fzf_configure_bindings
# --processes=`, disabling fzf.fish's Ctrl+Alt+P process picker. We DON'T carry
# that over, so the picker stays enabled. It's an undocumented taste choice from
# omarchy-fish being a 1:1 port of DHH's bash config (github.com/crmne/omafish,
# "follow DHH's dotfiles and muscle memory") — bash's fzf has no process picker.
# Nothing on our machine binds Ctrl+Alt+P, so there's no conflict to avoid.
#
# TRADEOFF: new additions to the upstream init.fish won't reach us silently —
# re-check the link above after omarchy-fish upgrades.
