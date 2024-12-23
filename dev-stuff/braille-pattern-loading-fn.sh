#!/usr/bin/env bash

function loader_animation {
    local pid=$!
    local display_txt="${2:-Loading}"
    local timeout_sec="${3:-10}"
    local clear_status_on_success=${4:-0}

    declare -a patterns_small=('⠟' '⠯' '⠷' '⠾' '⠽' '⠻')
    declare -a patterns_large=('⡿' '⣟' '⣯' '⣷' '⣾' '⣽' '⣻' '⢿')
    # ➜ ✓

    readarray -t colors < ./includes/data/loading-colors.list

    repeat(){
        local start=1
        local end=${1:-80}
        local str="${2:-=}"
        local range=$(seq $start $end)
        for i in $range ; 
            do echo -n "$str"; 
        done
    }

    cleanup() {
        #echo -en "\nExiting...\n"
        tput cnorm
    }

    trap cleanup EXIT
    tput civis

    local idx=0
    local color_idx=0
    local total_iterations=0
    local start_ts=$(date +%s)
    local elipses=0
    local update_increment=5 # Update the color and text every nth interation
    local loop_sleep_interval=0.1
    local return_code=0
    local loading_proc_status=0

    while [[ $loading_proc_status -ne 1 ]]; do
        ps -p $pid > /dev/null
        loading_proc_status=$?

        local current_ts=$(date +%s)
        local delta_ts=$((${current_ts}-${start_ts}))
        local duration=$(gdate -d@${delta_ts} -u +%H:%M:%S)
        local loading_txt="${display_txt}"$(repeat $elipses '.')

        if [[ $loading_proc_status -eq 1 ]]; then
            loading_txt="PID ${loading_proc_status} has finished and has closed"
            return_code=0
            color_idx=0
        else
            # Grow the elipses every 3 iterations
            if  [[ $(($total_iterations % $update_increment)) -eq 0 ]]; then
                let elipses++
                [[ $elipses -gt 3 ]] && elipses=1
            fi

            [[ $delta_ts -gt $timeout_sec ]] && 
                loading_txt="Failed to load after ${timeout_sec} seconds" && 
                return_code=2 &&
                color_idx=$((${#colors[@]}-1))
        fi


        printf "\r\e[38;2;%s;1m%s\e[0m \e[38;5;24m[PID %s]\e[0m \e[2;3m%-4s\e[0m %-50s" "${colors[$color_idx]}" "${patterns_large[$idx]}" $pid $duration "${loading_txt}"

        # If the process has closed, then we can exit the loop
        if [[ $loading_proc_status -eq 1 ]]; then
            [[ $clear_status_on_success -ne 1 ]] && 
                echo && 
                break;

            term_width=$(tput cols);

            # If clear_status_on_success is enabled, then clear the loading animation line and return
            # the carrage. 
            [[ $clear_status_on_success -eq 1 ]] && 
                printf "\r%${term_width}s\r" " " &&
                break;
        fi


        # Or if we've timed out
        [[ $delta_ts -gt $timeout_sec ]] && 
            echo && 
            break;

        let idx++
        let total_iterations++

        # Every 5th iteration, increment the color_idx
        [[ $(($total_iterations % $update_increment)) -eq 0 ]] && 
            [[ $color_idx -lt $((${#colors[@]}-1)) ]] && 
            let color_idx++

        [[ $idx -eq ${#patterns_large[@]} ]] && idx=0

        sleep ${loop_sleep_interval}
    done

    return $return_code
}

function loader {
    opts=("$@")
    pid=$1
    loading_text="Loading"
    timeout_sec=10
    hide_on_success=0

    #if no argument is passed this for loop will be skipped
    for ((i=0;i<${#opts[@]};i++));do
        case "${opts[$i]}" in
            -pid) [[ "${opts[$((i+1))]}" != "" ]] && pid=${opts[$((i+1))]} && ((i++)) ;;
            -timeout) [[ "${opts[$((i+1))]}" != "" ]] && timeout_sec="${opts[$((i+1))]}" && ((i++)) ;;
            -label)[[ "${opts[$((i+1))]}" != "" ]] && loading_text="${opts[$((i+1))]}" && ((i++)) ;;
            -hide) hide_on_success=1 ;;
            *) pid=${opts[$i]} ;;
        esac
    done

    loader_animation $pid "${display_txt}" $timeout_sec $hide_on_success
}

# nohup sleep 5 & 
# loader $! -label "Sleepy" -timeout 12 -hide && echo "Sleep is done"
# exit

nohup curl 'http://192.168.0.96:7125/server/history/list' --silent --output ./tmp/history.json 2>/dev/null &
loader $! -label "Loading printer history" -timeout 12 -hide && echo "Successfully downloaded history"

exit


#loader "Howdy" 5
#echo "Exited $?"

#loader "Loading..." 10
#echo "Exited $?"


nohupcurl 'http://192.168.0.96:7125/server/history/list' --silent --output ./tmp/history.json &
loader $! "Loading printer history" 10 1 && echo "Successfully download history"
#pid=$!
# while [ kill -0 $pid ]
# do
#   for i in "${spin[@]}"
#   do
#         echo -ne "\b$i"
#         sleep 0.1
#   done
# done