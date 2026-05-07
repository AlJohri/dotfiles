function cat --wraps cat
    if test (count $argv) -eq 1; and test -d $argv[1]
        cd $argv[1]
    else
        bat --paging=never --style=plain $argv
    end
end
