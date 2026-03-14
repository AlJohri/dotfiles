function ga --description "Create a new git worktree and branch"
    if test (count $argv) -eq 0
        echo "Usage: ga [branch name]"
        return 1
    end

    set -l branch $argv[1]
    set -l base (basename $PWD)
    set -l path "../$base--$branch"

    git worktree add -b $branch $path
    and mise trust $path
    and cd $path
end
