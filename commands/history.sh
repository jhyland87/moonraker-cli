#!/usr/bin/env bash

# https://blog.kellybrazil.com/2020/01/15/silly-terminal-plotting-with-jc-jq-and-jp/

#echo "[print] CLI_DIR: ${CLI_DIR:=.}"
source ${CLI_DIR:=.}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/file.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # file.sh
__module_name=${__module_file%%.sh} # file


history.description(){
	# DESCRIPTION: Description of this command
	echo "View print job history" 1>&2
	#exit
}

history.help() {
	echo -e "${_bld_}${_dirtyyellow_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Show recent print jobs${_none_}"
	echo -e "     moonraker history latest"
	echo
	#exit
}

[[ $# -eq 0 ]] && exit
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit


#[[ -z ${API_HOST} ]] && _error "No ${API_HOST} found" 1
#echo "API_HOST: ${API_HOST}"



# Note the quotes around '$TEMP': they are essential!
#eval set -- "$TEMP"

# http://192.168.0.96:7125/printer/objects/list
declare -a show_objects
DEBUG=false


history.list(){
	require_moonraker_connect

	# DESCRIPTION: Outputs the status of the current job
	# SYNTAX: moonraker job status
	_get /server/history/list 'limit=300' | 
		jq -r '[.result.jobs[] | {id: .job_id, filename: .filename, status: .status, start_time: .start_time, end_time: .end_time, print_duration: .print_duration}]' | json2table
		# | [.message, .webhooks, .printer, .filename, .progress, .percent] | @csv
}

history.totals(){
	require_moonraker_connect

	_get /server/history/totals | jq '.result.job_totals'
}

history.search(){
	_get /server/history/list | jq --arg filename "${1?No filename provided}" '.result.jobs[] | select(.filename | test($filename))'
}


history.get(){
	_get /server/history/job  "uid=${1?No job ID specified}" | jq '.result.job'

	#_get /server/history/job "uid=${1?No job ID specified}" | jq '.result'
}

# Find first match
#curl -s 'http://192.168.0.96:7125/server/history/list' | jq '.result.jobs[] | select(first((.filename | test("rc-cybertruck/ex_tailgate_3_v1__ASA_lh0.20mm_d15%_n0.4__K1C_20240822-144246.gcode"))))' 


# Find all matches
#curl -s 'http://192.168.0.96:7125/server/history/list' | jq '.result.jobs[] | select((.filename | test("rc-cybertruck")))' 
_debug "Arguments: $# - $*"

# Default the subcommand to history.list
subcmd="${1:-list}"

subcmd_fn="${__module_name}.$subcmd"

_debug "Subcommand: $subcmd"
shift

#cmd_type=$(type -t "${subcmd_fn}")

# Make sure the sumcommand is a defined function
if [[ $(type -t "${subcmd_fn}") != 'function' ]]; then
	_error "The command ${subcmd} is not a valid subcommand for ${__module_name}" 
	exit 2
fi

# Execute the full command
eval ${subcmd_fn} ${@@Q}

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