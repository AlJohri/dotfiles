function git_status_or_worktrees
    if test "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true
        git status $argv
    else if git rev-parse --git-dir &>/dev/null
        echo "In a bare repository. Showing status across all worktrees:"
        echo ""

        set -l current_worktree ""
        set -l current_branch ""
        set -l is_bare ""

        for line in (git worktree list --porcelain; echo "")
            if string match -qr '^worktree (.+)' -- $line
                set current_worktree (string match -r '^worktree (.+)' -- $line)[2]
            else if string match -qr '^branch refs/heads/(.+)' -- $line
                set current_branch (string match -r '^branch refs/heads/(.+)' -- $line)[2]
            else if test "$line" = bare
                set is_bare 1
            else if test -z "$line"
                # End of stanza
                if test -n "$current_worktree" -a -z "$is_bare"
                    set -l branch_display $current_branch
                    if test -z "$branch_display"
                        set branch_display "detached"
                    end

                    echo "── $current_worktree ($branch_display)"

                    set -l ahead_behind (git -C $current_worktree rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)
                    if test -n "$ahead_behind"
                        set -l behind (echo $ahead_behind | awk '{print $1}')
                        set -l ahead (echo $ahead_behind | awk '{print $2}')
                        if test "$ahead" -gt 0 -o "$behind" -gt 0
                            echo "   ↑$ahead ↓$behind"
                        end
                    end

                    set -l status_output (git -C $current_worktree status --short 2>/dev/null)
                    if test -n "$status_output"
                        for sline in $status_output
                            echo "   $sline"
                        end
                    else
                        echo "   clean"
                    end
                    echo ""
                end

                set current_worktree ""
                set current_branch ""
                set is_bare ""
            end
        end
    else
        echo "Not in a git repository."
        return 1
    end
end
