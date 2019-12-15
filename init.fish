################################################################################
############  AutoVenv for Fish Shell v2019.03.28 by @TimothyBrown  ############
################################################################################
## AutoVenv Settings
if status is-interactive
    test -z "$autovenv_announce"
        and set -g autovenv_announce "yes"
    test -z "$autovenv_enable"
        and set -g autovenv_enable "yes"
end

# Gets particular elements from an array
# eg. $some_array | select 1 3
# Returns the first and 3rd elements
function select
  read --local --array --null arr
  echo $arr[$argv]
end

## AutoVenv Function
# Activates on directory changes.
function autovenv --on-variable PWD -d "Automatic activation of Python virtual environments"
    # Check for the enable flag and make sure we're running interactive, if not return.
    test ! "$autovenv_enable" = "yes"
        or not status is-interactive
        and return
    # Start at PWD (prsent working directory, see if there is a subfolder that contains bin/activate.fish
    # ie. start at $PWD/<any subdir>/bin/activate.fish
    # If that doesn't exist, try $PWD/../<any subdir>/bin/activate.fish
    # Keep going until we cannot go any further
    set -l _tree "$PWD/."
    set -l _done false
    while true
        set _tree (string split -r -m 1 -n '/' "$_tree")[1]
        if ! string match -q -- "/*" $_tree 
            # This is a hack to stop when we have ascended all the way up to the top of the tree.
            # The string split command above eventually returns something like "home" when it tries
            # to split "/home". So the lack of a slash is what we do to tell us that "it's time to stop"
            break
        end
        for _venv_dir in (find "$_tree" -maxdepth 1 -type d 2> /dev/null)
            if test -e "$_venv_dir/bin/activate.fish"
                set _source "$_venv_dir/bin/activate.fish"
                if test "$autovenv_announce" = "yes"
                    set -g __autovenv_old $__autovenv_new
                    set -g __autovenv_new (basename $_tree)
                    set venv_dir $_venv_dir
                end
                set _done true
                break
            end
        end
        if $_done
            break
        end

    end
    # If we're *not* in an active venv and the venv source dir exists we activate it and return.
    if test -z "$VIRTUAL_ENV" -a -e "$_source"
        source "$_source"
        if test "$autovenv_announce" = "yes"
            echo "Activated Virtual Environment ($__autovenv_new)"
        end
    # Next we check to see if we're already in an active venv. If so we proceed with further tests.
    else if test -n "$VIRTUAL_ENV"
        # Check to see if our CWD is inside the venv directory.
        set _dir (string match -n "$VIRTUAL_ENV*" "$venv_dir")
        # If we're no longer inside the venv dirctory deactivate it and return.
        if test -z "$_dir" -a ! -e "$_source"
            deactivate
            if test "$autovenv_announce" = "yes"
                echo "Deactivated Virtual Enviroment ($__autovenv_new)"
                set -e __autovenv_new
                set -e __autovenv_old
            end
        # If we've switched into a different venv directory, deactivate the old and activate the new.
        else if test -z "$_dir" -a -e "$_source"
            deactivate
            source "$_source"
            if test "$autovenv_announce" = "yes"
                echo "Switched Virtual Environments ($__autovenv_old => $__autovenv_new)"
            end
        end
    end
end
################################################################################
