#!/bin/sh
git_config_def () {
    echo "user.name=Jonathan Browne"
    echo "user.email=12983479+JBYoshi@users.noreply.github.com"
    echo "core.sshCommand=ssh jbrowne@linux.cs.utexas.edu ssh"
    echo "url.ssh://git@github.com.insteadOf=https://github.com"
}

git_config_set() {
    git_config_def | while read -r l
    do
        git config "$@" "$(echo $l | cut -d'=' -f1)" "$(echo $l | cut -d'=' -f2)"
    done
}

git_clone_setup() {
    # Note the -c AFTER the "clone" part. This means the configs are automatically applied to the repository.
    IFS='
'
    git clone $(for i in $(git_config_def); do echo -c; echo $i; done) --recurse-submodules "$@"
}

make_git_cmd() {
    IFS='
'
    echo "#!/bin/sh"
    echo "# Jonathan Browne: custom Git command with my own configs"
    printf 'git $EXTRA_CONFIG '
    for i in $(git_config_def)
    do
        printf -- "-c %q " $i
    done
    echo '"$@"'
}

main() {
    if ! test -t 0
    then
        if test -t 1
        then
            echo "Using STDOUT as input."
            exec 0<&1
        else
            echo "No TTY is available. Try downloading the script and running it separately."
            exit 1
        fi
    else
        echo "Using STDIN as input."
    fi

    echo "What setup is this?"
    echo "1) Shared everything"
    echo "2) Personal Git repository, shared user"
    echo "3) Personal user, shared computer"
    user_type=0
    while [ "$user_type" -ne "$user_type" ] || [ "$user_type" -le 0 ] || [ "$user_type" -gt 3 ]
    do
        read -p "Select option: " user_type
    done

    if test $user_type = "1"
    then
        echo "Setting up with command scope."
        FILE="$HOME/jbgit"
        make_git_cmd > $FILE
        chmod u+x $FILE
        echo "Custom Git command saved to $FILE."
    elif test $user_type = "2"
    then
        echo "Setting up with Git scope."
        if git rev-parse --show-toplevel >/dev/null 2>/dev/null
        then
            echo "Setting up existing repository."
            git_config_set
        else
            echo "You are not currently in a Git repository, so this will clone a new one."
            read -p "Enter the SSH clone URL: " clone_url
            read -p "Enter the directory to clone to (or leave blank for the default): " clone_dir
            if test -n "$clone_dir"
            then
                git_clone_setup "$clone_url" "$clone_dir"
            else
                git_clone_setup "$clone_url"
            fi
        fi
    elif test $user_type = "3"
    then
        echo "Setting up with user scope."
        git_config_set --global
    fi

    exit 0
}

main
