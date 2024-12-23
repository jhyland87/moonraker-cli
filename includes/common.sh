#!/usr/bin/env bash



cwd=$(dirname "${BASH_SOURCE[0]}")

source "${cwd}/colors.sh"

#declare -rgx CLI_DIR=$(dirname $(realpath $0))
#declare -rgx CLI_NAME=$(basename $0)
#declare -rgx CLI_PID=$$

_DATE_BIN=$(type -P gdate || type -P date)
_DATE_TYPE=$(basename $_DATE_BIN)


if [[ $(basename ${_DATE_BIN}) == "gdate" ]]; then
	_TIMESTAMP_FORMAT="%FT%R:%S.%3NZ"
else
	_TIMESTAMP_FORMAT="%FT%R:%S%z"
fi

#declare -r _TIMESTAMP_FORMAT_G="%FT%R:%S.%3NZ"

# Just a simple timestamp function, used by log entries
_ts(){
	date +%s
}

# Output an ISOTime style date string (taken from JS new Date().toISOString())
# eg: 2024-08-12T15:31:24.069Z
_toISOtime() {
	#set -x
	if test ! -t 0; then
		parseDate=$(cat < /dev/stdin);
	elif test -n "${1}"; then
		parseDate="${1}";
	else
		#gdate +"%FT%R:%S.%3NZ";
		if [[ $_DATE_TYPE == "gdate" ]]; then
			$_DATE_BIN --iso-8601=seconds | sed -E 's/([0-9]):([0-9]{2})$/\1\2/'
		else
			$_DATE_BIN +"%FT%R:%S%z" 
		fi

		#set +x
		return 0
	fi;

	#echo "parseDate: ${parseDate}" 1>&2
	#echo "_DATE_BIN: ${_DATE_BIN}" 1>&2

	if [[ $_DATE_TYPE == "gdate" ]]; then
		$_DATE_BIN --iso-8601=seconds --date="@${parseDate}" | sed -E 's/([0-9]):([0-9]{2})$/\1\2/'
	else
		$_DATE_BIN -r ${parseDate} +"%FT%R:%S%z" 
	fi

	#set +x
	

	# $ /bin/date +"%FT%R:%S%z"
	# 2024-08-13T06:33:10-0700

	# $ /usr/local/bin/gdate --iso-8601=seconds --date="@$(date +%s)"
	# 2024-08-13T06:33:07-07:00

	# $ /usr/local/bin/gdate --iso-8601=seconds --date="@$(date +%s)" | sed -E 's/([0-9]):([0-9]{2})$/\1\2/'
	# 2024-08-13T06:33:07-0700
}

_char_count_a(){
	local _data
	if test ! -t 0; then
		#cat < /dev/stdin  | tr -d '\n' | wc -c  | tr -d ' '
		_data=$(cat < /dev/stdin)
		#return
	else 
		_data="$@" 
	fi

	echo ${#_data}
	#printf "$@" | wc -c  | tr -d ' '
}

# Gets user input from either STDIN or Parameters
# NOTE: If both STDIN and parameters are provided, then	stdin will take precedence.
# TODO: Should this also check if params are filenames and output the content length?..
# Examples:
# 	$ printf "foo" | _get_input
#		foo
# 	$ _get_input "bar"
#		bar
# 	$ printf "foo" | _get_input "bar"
# 	foo
_get_input(){
	set -x
	local _input

	test ! -t 0 && _input=$(cat < /dev/stdin)

	[[ -z ${_input} && -n "${1}" ]] && _input="$@"

	[[ -z "${_input}" ]] && 
		return 1

	echo "$_input"
	set +x
}


# Count chars of input - either stdin or param list
_char_count(){
	local _input=$(_get_input $@)
	
	echo ${#_input}
	#_get_input "${_input}" | tr -d '\n' | wc -c  | tr -d ' '
}

_get_widest_from_list() {
	local _result _widest=0  #_input=$(_get_input $@ < /dev/stdin  | tr ' ' '\n')

	#echo "> _get_widest_from_list _input: $_input" 1>&2

	_get_input $@  | tr ' ' '\n' | while read p; do
	#for p in $_input; do
	echo "> _get_widest_from_list p: $p" 1>&2
		len=$(_char_count "$p")

	echo -e "> _get_widest_from_list len($p): $len" 1>&2
		if [[ $len -gt $_widest ]]; then
			_widest=$len
			_result="${p}"
		fi
	done # <(cat < /dev/stdin | _get_input $@  | tr ' ' '\n')


	printf "${_result}"
}

_get_widest_len_from_list() {
	_get_widest_from_list $@ < /dev/stdin | _char_count
}


# Get filename relative to root of moonraker script
# Example: execution from within commands/print.sh would output `commands/print.sh`
_relative_filename() {
	# In the moonraker file is the CLI_DIR definition: 
	# 	declare -rgx CLI_DIR=$(dirname $(realpath $0))

	realpath --relative-to="${CLI_DIR}" $0
}

# Get directory name relative to root of moonraker script
# Example: execution from within commands/print.sh would output `commands`
_relative_base() {
	dirname $(_relative_filename)
}

_hr() {
	local termCols=${COLUMNS:-$(tput cols)}

	# Get the char to be repeated, default to -
	local char="${1:-—}" 

	# Width of the char being repeated
	local charWidth=${#char}

	# How wide the hr should be (defaults to -, but can be changed using the 2nd argument)
	local hrWidth="${2:-${termCols}}"

	# How many times $char needs to be repeated to get an hr of $printWidth columns wide
	local repeatCharCount=$((${hrWidth}/${charWidth}))

	#
	#local repeatWidth=$((${hrWidth}/${charWidth}))

	#echo "char: ${char}" 1>&2
	#echo "charWidth: ${charWidth} (${char})" 1>&2
	#echo "termCols: ${termCols}" 1>&2
	#echo "hrWidth: ${hrWidth}" 1>&2
	#echo "repeatCharCount: ${repeatCharCount}" 1>&2

	echo -en "${_hr_}" 1>&2
	printf "${char}%.0s" `seq -s ' ' 1 ${repeatCharCount}` 1>&2
	echo -e "${_none_}" 1>&2
	return 
	for i in $(seq 1 ${repeatCharCount}) ; do 
		printf "${char}" 1>&2
	done
	echo -e "${_none_}"
}

_decolor(){
	if test ! -t 0; then
		cat < /dev/stdin | sed -r "s/[[:cntrl:]]\[[0-9;]{1,100}m//g"
		return 0
	fi

	if [[ -z ${_input} && -n "${1}" ]]; then 
		echo -ne "$@" | sed -r "s/[[:cntrl:]]\[[0-9;]{1,100}m//g"
		return 0
	fi

	return 1
}

screen_restore(){
	tput clear
	echo "Restoring screen..." 
	sleep 0.5
	stty echoctl
	stty echo
	tput cnorm

	# rmcup - Remove Memory CUrsor Positon
	tput rmcup
	exit
}

# temp_terminal - Creates a new temporary terminal (clears the screen), 
# disables the ctrl character outputs and user input echo and creates a 
# trap for ctrl+x or ctrl+c to restore the status of the temporary 
# terminal
#
#	Example: The below will put the while loop output in a new temporary
# 				 terminal, but will kill the loop and restore the previous
# 				 terminal status when SIGINT is triggered.
# 	temp_terminal
# 	while true; do moonraker print status; sleep 1; done
temp_terminal(){
	trap 'screen_restore' SIGINT SIGTERM SIGQUIT
	trap "" SIGTSTP

	# smcup - Save Memory CUrsor Positon
	tput smcup
	stty -echoctl
	stty -echo
	tput civis
}

# Check if a given string (first param) is in the remaining value(s)
#   declare -a myarray=(foo bar baz)
#   in_array bang ${myarray[@]} # returns non-zero
#   myarray+=(bang)
#   in_array bang ${myarray[@]} # Returns zero
#   in_array ban ${myarray[@]}  # Returns non-zero
#
# Use with associative arrays
#   declare -A mydict=([foo]=bar)
#   in_array baz ${mydict[@]} # Returns non-zero
# 	mydoct[baz]=bang
# 	in_array baz ${mydict[@]} # Returns zero 
# 
# Check if a key is in an associative array
# 	in_array foo ${!mydoct[@]} # Returns zero
in_array(){
	local searchfor="${1?No search value provided}"
	shift

	printf '%s\0' "$@" | grep -qw --null "${searchfor}"
}

# Nanoseconds to seconds
# Usage
# 	ns2sec nanoseconds [accuracy]
# 
# Examples
# 	$ ns2sec `gdate +%N`  	
# 	.641833
# 	$ ns2sec `gdate +%N` 2 	
# 	.64
#
ns2sec(){
	bc <<< "scale=${2:-6}; ${1?no nanoseconds value provided}/1000000000"
}

_h1(){
	echo -e "${_h1_}$@${_none_}\n"
}

_h2(){
	echo -e "${_h2_}$@${_none_}\n"
}

_h3(){
	echo -e "${_h3_}$@${_none_}\n"
}

json2table(){
	jq --monochrome-output --raw-output \
			-L "${cwd}/../jq" \
			--from-file "${cwd}/../jq/modifiers/array_of_objects_to_csv.jq" \
			--arg output tsv | 
		column -ts $'\t'
}

_greater_than(){
	test $(echo "${1?No value specified to compare against} > ${2?No comparitor specified}" | bc -l) == 1
}

_less_than(){
	test $(echo "${1?No value specified to compare against} < ${2?No comparitor specified}" | bc -l) == 1
}

_get_percent(){
	if _greater_than $1 $2; then
		a=$1
		b=$2
	else
		a=$2
		b=$1
	fi
	result=$(echo "scale=1;(${b}/${a})*100" |bc -l)
	echo "${result}%"
}


# Example usage:
# 	curl 'http://192.168.0.96:7125/server/history/list' --silent --output ./tmp/history.json &
# 	loader_animation $! "Loading printer history" 10 1 && echo "Successfully download history"
function loader_animation {
    local pid=$!
    local display_txt="${2:-Loading}"
    local timeout_sec="${3:-10}"
    local show_duration=${4:-0}
    local clear_status_on_success=${5:-0}
	local post_pause_sec=${6:-0}
	local command=$(ps -o command="" -p $pid)
	local command_bin=$(ps -o comm="" -p $pid)

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
	local cursor_line=${LINENO}

	# Simple home function for hte cursor. This works better than using just \r alone since \r doesn't
	# account for the fact that users can scroll or hit enter while the program is running.
	_home(){
		tput cup $cursor_line 0 && printf '\r';
	}

    while [[ $loading_proc_status -ne 1 ]]; do
        ps -p $pid > /dev/null
        local loading_proc_status=$?
        local current_ts=$(date +%s)
        local delta_ts=$((${current_ts}-${start_ts}))
        local duration=$(gdate -d@${delta_ts} -u +%H:%M:%S)
        local loading_txt="${display_txt}"$(repeat $elipses '.')

        if [[ $loading_proc_status -eq 1 ]]; then
            loading_txt="${command_bin}: PID ${pid} has completed"
            return_code=0
            color_idx=0
        else
            # Grow the elipses every 3 iterations
            if  [[ $(($total_iterations % $update_increment)) -eq 0 ]]; then
                let elipses++
                [[ $elipses -gt 3 ]] && elipses=1
            fi

            [[ $delta_ts -gt $timeout_sec ]] && 
                loading_txt="${command_bin}: Failed to load after ${timeout_sec} seconds" && 
                return_code=2 &&
                color_idx=$((${#colors[@]}-1))
        fi

		_home
		
		if [[ $show_duration -eq 1 ]]; then
	        printf "\e[38;2;%s;1m%s\e[0m \e[38;5;24m[PID %s]\e[0m \e[2;3m%-4s\e[0m %-50s" "${colors[$color_idx]}" "${patterns_large[$idx]}" $pid $duration "${loading_txt}"
		else
			printf "\e[38;2;%s;1m%s\e[0m %-50s" "${colors[$color_idx]}" "${patterns_large[$idx]}" "${loading_txt}"
		fi

        # If the process has closed, then we can exit the loop
        if [[ $loading_proc_status -eq 1 ]]; then
			[[ $post_pause_sec -ne 0 ]] && sleep $post_pause_sec

            if [[ $clear_status_on_success -ne 1 ]]; then
			    echo
			else
				_home && printf "%$(tput cols)s\r" " "
			fi

            break;
        fi

        # Or if we've timed out
       	if [[ $delta_ts -gt $timeout_sec ]]; then
			[[ $post_pause_sec -ne 0 ]] && sleep $post_pause_sec

			echo
			break;
		fi 

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


# LOADER - 	This is a simple wrapper around loader_animation, but it takes command line style
# 			switches for the arguments, just to make it a little easeir to implement
# Example usage:
# 	curl 'http://192.168.0.96:7125/server/history/list' --silent --output ./tmp/history.json &
# 	loader $! -label "Loading printer history" -timeout 10 -hide && echo "Successfully download history"
function loader {
    local opts=("$@")
    local pid=$1
    local loading_text="Loading"
    local timeout_sec=10
    local hide_on_success=0
	local show_duration=0
	local post_pause_sec=0

    #if no argument is passed this for loop will be skipped
    for ((i=0;i<${#opts[@]};i++));do
        case "${opts[$i]}" in
            --pid|-p) [[ "${opts[$((i+1))]}" != "" ]] && pid=${opts[$((i+1))]} && ((i++));;
            --timeout|-t) [[ "${opts[$((i+1))]}" != "" ]] && timeout_sec="${opts[$((i+1))]}" && ((i++));;
            --label|-l) [[ "${opts[$((i+1))]}" != "" ]] && loading_text="${opts[$((i+1))]}" && ((i++));;
            --pause-sec) [[ "${opts[$((i+1))]}" != "" ]] && post_pause_sec="${opts[$((i+1))]}" && ((i++));;
            --pause) post_pause_sec=1;;
            --no-pause) post_pause_sec=0;;
            --hide|-h) hide_on_success=1;;
            --show|-s) hide_on_success=0;;
            --duration|-d) show_duration=1;;
            --no-duration) show_duration=0;;
            *) pid=${opts[$i]};;
        esac
    done

    loader_animation $pid "${loading_text}" $timeout_sec $show_duration $hide_on_success $post_pause_sec
}
