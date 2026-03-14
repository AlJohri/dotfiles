function gd --description "Remove current git worktree and its branch"
    gum confirm "Remove worktree and branch?"; or return

    set -l cwd (pwd)
    set -l worktree (basename $cwd)
    set -l root (string replace -r '--.*' '' $worktree)
    set -l branch (string replace -r '.*?--' '' $worktree)

    if test "$root" != "$worktree"
        cd "../$root"
        and git worktree remove $cwd --force
        and git branch -D $branch
    end
end
