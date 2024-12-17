#!/usr/bin/env bash

#cd /Users/justin.hyland/Documents/scripts/bash/moonraker-cli/dev-stuff

declare -a patterns_small=('⠟' '⠯' '⠷' '⠾' '⠽' '⠻')
declare -a patterns_large=('⡿' '⣟' '⣯' '⣷' '⣾' '⣽' '⣻' '⢿')
# ➜ ✓

readarray -t colors < ./includes/data/loading-colors.list

repeat(){
	local start=1
	local end=${1:-80}
	local str="${2:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
}

cleanup() {
    tput cnorm
}

trap cleanup EXIT

tput civis

idx=0
color_idx=0
total_iterations=0
start_ts=$(date +%s)
failure_threshold_sec=10
elipses=0
update_increment=5 # Update the color and text every nth interation
loop_sleep_interval=0.1

while : ; do
    current_ts=$(date +%s)
    delta_ts=$((${current_ts}-${start_ts}))
    duration=$(gdate -d@${delta_ts} -u +%H:%M:%S)

    if  [[ $(($total_iterations % $update_increment)) -eq 0 ]]; then
        let elipses++

        [[ $elipses -gt 3 ]] && elipses=1
    fi
    
    if [[ $delta_ts -gt $failure_threshold_sec ]]; then
        loading_txt="Failed to load after ${failure_threshold_sec} seconds"
    else 
        loading_txt="Loading"$(repeat $elipses '.')
    fi

    printf "\r\e[38;2;%s;1m%s\e[0m [%-2s] \e[2m%-4s\e[0m %-50s" "${colors[$color_idx]}" "${patterns_large[$idx]}" $color_idx $duration "${loading_txt}"

    [[ $delta_ts -gt $failure_threshold_sec ]] && echo && break

    let idx++
    let total_iterations++

    # Every 5th iteration, increment the color_idx
    [[ $(($total_iterations % $update_increment)) -eq 0 ]] && [[ $color_idx -lt $((${#colors[@]}-1)) ]] && let color_idx++

    [[ $idx -eq ${#patterns_large[@]} ]] && idx=0

    sleep ${loop_sleep_interval}
done

exit
for char in ${patterns_small[@]}; do
    echo -en "\r${char}"
    sleep ${loop_sleep_interval}
done

echo
echo

for char in ${patterns_large[@]}; do
    echo -en "\r${char}"
    sleep ${loop_sleep_interval}
done

echo
echo