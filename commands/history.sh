#!/usr/bin/env bash

# https://blog.kellybrazil.com/2020/01/15/silly-terminal-plotting-with-jc-jq-and-jp/

#echo "[print] CLI_DIR: ${CLI_DIR}"
source ${CLI_DIR}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh

#export -p




#[[ -z ${API_HOST} ]] && _error "No ${API_HOST} found" 1
#echo "API_HOST: ${API_HOST}"



# Note the quotes around '$TEMP': they are essential!
#eval set -- "$TEMP"

# http://192.168.0.96:7125/printer/objects/list
declare -a show_objects
DEBUG=false

history_description(){
	# DESCRIPTION: Description of this command
	echo "This command is for managing jobs" 1>&2
}

history_help() {
	echo -e "${_bld_}${_dirtyyellow_}JOB COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Show print job status${_none_}"
	echo -e "     moonraker job status"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Start print job${_none_}"
	echo -e "     moonraker job start ${_ul_}filename.gcode${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Cancel print job${_none_}"
	echo -e "     moonraker job cancel"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Pause print job${_none_}"
	echo -e "     moonraker job pause"
	echo 
	echo -e "  ${_bld_}${_ital_}${_blue_}Resume print job${_none_}"
	echo -e "     moonraker job resume"
	echo
}


history_list (){
	# DESCRIPTION: Outputs the status of the current job
	# SYNTAX: moonraker job status
	_get /server/history/list 'limit=300' | 
		jq -r '.result.jobs[] | {id: .job_id, filename: .filename, status: .status, start_time: .start_time, end_time: .end_time, print_duration: .print_duration}'
		# | [.message, .webhooks, .printer, .filename, .progress, .percent] | @csv
}



_debug "Arguments: $# - $*"

subcmd="$1"

_debug "Subcommand: $subcmd"
shift


cmd_type=$(type -t "history_${subcmd}")



if [[ ${cmd_type} == 'function' ]]; then
	history_$subcmd $*
else
	_error "The command ${subcmd} is not a valid function" 1
fi


#TEMP=$(getopt -o hlsSTRP: --long help,list,status,stop,start,pause,resume: -n 'wtf' -- "$*")

#[[ $? != 0 ]] && _error "Getopt failed" 1

#while true; do
#	case "$1" in
# 		-h | --help ) help; exit 0; shift ;;
#	  -s | --status ) show_job_state; exit 0; shift ;;
#		-- ) shift; break ;;
#	  * ) break ;;
#	esac
#done