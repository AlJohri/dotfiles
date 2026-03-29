# Override of upstream: https://github.com/omacom-io/omarchy-fish/blob/master/functions/zd.fish
# Adds `cd -` support and directory history tracking (dirprev).
# Note: unlike fish's stock cd, we don't clear dirnext on navigation (nextd/Alt+Right may be stale).
function zd --description 'zoxide-backed cd'
    if test (count $argv) -eq 0
        set -g -a dirprev $PWD
        builtin cd ~
    else if test "$argv[1]" = -
        prevd
    else if test -d $argv[1]
        set -g -a dirprev $PWD
        builtin cd -- $argv[1]
    else
        z $argv; and printf "\U000F17A9 "; and pwd || echo "Error: Directory not found"
    end
end
