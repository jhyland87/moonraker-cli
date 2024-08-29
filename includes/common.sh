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
	#echo;
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
	echo "Restoring screen..." 
	sleep 1
	stty echoctl
	stty echo
	tput cnorm
	tput clear

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
	trap 'screen_restore' SIGINT
	#trap 'screen_restore' SIGSTOP
	#trap 'screen_restore' SIGQUIT
	#trap 'screen_restore' SIGKILL
	#trap 'screen_restore' SIGTRAP
	#trap 'screen_restore' SIGTERM

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