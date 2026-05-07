# Vendored from upstream: https://github.com/omacom-io/omarchy-fish/blob/master/functions/cd.fish
# On Omarchy this is provided by the omarchy-fish package at
# /usr/share/fish/vendor_functions.d/cd.fish; vendoring here so `cd` routes
# through `zd` (zoxide-backed) on macOS too.
function cd --wraps=zd --description 'alias cd=zd'
    zd $argv
end
