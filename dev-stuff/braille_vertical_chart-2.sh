#!/usr/bin/env bash

. ./includes/common.sh

max_value=$(tput lines)

function _randInt {
    local limit=${1:-10}

    echo -n $((RANDOM % (${limit}+1)))
}

function _randTenPercent {
    [[ $((RANDOM % 10)) -eq 5 ]]
}

function _randChange {
    echo -e $(((RANDOM % 3)-1))
}

function _randbool {
    test $((RANDOM % 2)) -eq 1
}

loop_sleep_interval=0.1

temp_terminal

while : ; do
    tput cup 0 0
    curl http://192.168.0.96:4408/machine/system_info http://192.168.0.96:4408/machine/proc_stats http://192.168.0.96:4408/printer/objects/query \
        --get --silent \
        --data print_stats --data virtual_sdcard --data temperature_sensor%20mcu_temp \
        --data display_status --data system_stats --data mcu --data mcu%20rpi | 
        ./jq/modifiers/chart_data_parser_with_headers.jq | 
        tee -a data.log | 
        ./dev-stuff/braille_vertical_chart_with_headers.awk
    sleep $loop_sleep_interval
done

echo