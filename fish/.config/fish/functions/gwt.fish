function gwt
    if test (count $argv) -eq 0
        command gwt
    else if test "$argv[1]" = "prune"
        command gwt prune
    else
        set dir (command gwt $argv)
        and builtin cd $dir
    end
end
