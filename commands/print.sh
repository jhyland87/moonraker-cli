#!/usr/bin/env bash

source ./includes/prompts.sh

_info "Hello from job"
#export -p


#[[ -z ${API_HOST} ]] && _error "No ${API_HOST} found" 1
#echo "API_HOST: ${API_HOST}"



# Note the quotes around '$TEMP': they are essential!
#eval set -- "$TEMP"

# http://192.168.0.96:7125/printer/objects/list
declare -a show_objects
DEBUG=false

print_description(){
	# DESCRIPTION: Description of this command
	confirm_action
	echo "This command is for managing jobs"
}

print_help() {
	echo "Help..."

	declare -pf  | grep -E -A4  '^print_' # | sed -E 's/^declare .* print_//g'
}

export -f print_help print_description

show_print_state() {
	local limit="${1:-20}"

	curl ${API_HOST} \
		--request-target /api/printer \
		--request GET --silent |
			jq 
}

_debug "Arguments: $# - $*"

subcmd="$1"

_debug "Subcommand: $subcmd"
shift


print_status (){
	# DESCRIPTION: Outputs the status of the current job
	# SYNTAX: moonraker print status
	_get /printer/objects/query 'webhooks&virtual_sdcard&print_stats' | 
		jq '.result.status | {message: last(.print_stats.message, .webhooks.state_message | select(. != "")), webhooks: .webhooks.state, printer: .print_stats.state, filename: .print_stats.filename, progress: .virtual_sdcard.progress} | with_entries(if .value == null or .value == "" then empty else . end)'
}

print_pause(){
	# DESCRIPTION: Pause the current job (if there is one)
	# SYNTAX: moonraker print pause
	printf "Pausing current print job... " 
	_post /printer/print/pause | jq --raw-output '.result'
}

print_resume(){
	# DESCRIPTION: Resumes a paused print job
	# SYNTAX: moonraker print resume
	printf "Resuming current print job... " 
	_post /printer/print/resume | jq --raw-output '.result'
}

print_cancel(){
	# DESCRIPTION: Cancels a job currently being printed
	# SYNTAX: moonraker print cancel
	printf "Cancelling current print job... " 
	_post /printer/print/cancel | jq --raw-output '.result'
}

print_start(){
	# DESCRIPTION: Start a new print job
	# SYNTAX: moonraker print start <filename>

	local filename="${1?-No filename provided}"

	gprintf "Starting print for %q... " "${filename}"

	_post /printer/print/start "filename=${filename}" | jq --raw-output '.result'

	#/printer/print/start?filename=test_print.gcode
}

cmd_type=$(type -t "print_${subcmd}")



if [[ ${cmd_type} == 'function' ]]; then
	print_$subcmd $*
else
	_error "The command ${subcmd} is not a valid function" 1
fi


#TEMP=$(getopt -o hlsSTRP: --long help,list,status,stop,start,pause,resume: -n 'wtf' -- "$*")

#[[ $? != 0 ]] && _error "Getopt failed" 1

#while true; do
#	case "$1" in
# 		-h | --help ) help; exit 0; shift ;;
#	  -s | --status ) show_print_state; exit 0; shift ;;
#		-- ) shift; break ;;
#	  * ) break ;;
#	esac
#done