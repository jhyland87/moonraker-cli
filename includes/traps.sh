

set -T

function _trap_DEBUG() {
    echo "# $BASH_COMMAND";
    while read -r -e -p "debug> " _command; do
        if [ -n "$_command" ]; then
            eval "$_command";
        else
            break;
        fi;
    done
}

trap '_trap_DEBUG' DEBUG

#my_name="${1:-Justin}"

#printf "Hello %s\n" "${my_name}"


#trap '_trap_EXIT' EXIT
#trap '_trap_RETURN' RETURN
#trap '_trap_ERR' ERR
#trap '_trap_DEBUG' DEBUG
