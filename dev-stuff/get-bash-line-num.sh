#!/bin/bash       


function return_to_line {
    local _bashlineno="${BASH_LINENO[*]}"

    log
    echo -e "\n\n\n\n"
    echo "foooo"
    log
    echo -e "\n\n\n\n"
    echo "bar"
    log
    echo -e "\n\n\n\n"

    log

    tput cup $_bashlineno 0
    
}
function log() {
    local _bashlineno="${BASH_LINENO[*]}"
    echo "BASH_LINENO[*]: ${_bashlineno}"
    echo "BASH_LINENO[0]: ${BASH_LINENO[0]}"
    echo "BASH_LINENO[1]: ${BASH_LINENO[1]}"
    echo "LINENO: $LINENO"
}

function foo() {
    log "$@"
}

return_to_line