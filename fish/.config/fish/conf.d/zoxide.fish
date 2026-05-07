# Vendored from upstream: https://github.com/omacom-io/omarchy-fish/blob/master/conf.d/init.fish
# On Omarchy this runs from /usr/share/fish/vendor_conf.d/init.fish (omarchy-fish
# package). Vendoring just the zoxide bit here so `z` and the chpwd hook are
# defined on macOS too. The mise/starship inits are handled by their own conf.d
# files; vi keybindings are intentionally skipped (config.fish opts into default).
if status is-interactive
    if command -v zoxide &>/dev/null
        zoxide init fish | source
    end
end
