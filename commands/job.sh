#!/usr/bin/env bash

# https://blog.kellybrazil.com/2020/01/15/silly-terminal-plotting-with-jc-jq-and-jp/



#echo "[print] CLI_DIR: ${CLI_DIR}"
source ${CLI_DIR}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/file.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # file.sh
__module_name=${__module_file%%.sh} # file


#[[ -z ${API_HOST} ]] && _error "No ${API_HOST} found" 1
#echo "API_HOST: ${API_HOST}"


# Note the quotes around '$TEMP': they are essential!
#eval set -- "$TEMP"

# http://192.168.0.96:7125/printer/objects/list
declare -a show_objects
DEBUG=false

job.description(){
	# DESCRIPTION: Description of this command
	echo "This command is for managing jobs" 1>&2
}

job.help() {
	echo -e "${_bld_}${_dirtyyellow_}${__module_name^^} COMMANDS${_none_}"
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

show_job_state() {
	local limit="${1:-20}"

	curl ${API_HOST} \
		--request-target /api/printer \
		--request GET --silent |
			jq 
}

job.status (){
	require_moonraker_connect

	# DESCRIPTION: Outputs the status of the current job
	# SYNTAX: moonraker job status
	_get /printer/objects/query 'webhooks&virtual_sdcard&print_stats' | 
		jq -r '.result.status | {message: last(.print_stats.message, .webhooks.state_message | select(. != "")), webhooks: .webhooks.state, printer: .print_stats.state, filename: .print_stats.filename, progress: .virtual_sdcard.progress, percent: (.virtual_sdcard.progress*100|tostring | .[0:5] + "%") } | with_entries(if .value == null or .value == "" then empty else . end) '
		# | [.message, .webhooks, .printer, .filename, .progress, .percent] | @csv
}

job.pause(){
	require_moonraker_connect

	# DESCRIPTION: Pause the current job (if there is one)
	# SYNTAX: moonraker job pause

	is_paused && 
		_error "Print job already paused" && 
		return 1

	printf "Pausing current print job... " 

	_post /printer/print/pause | jq --raw-output '.result'
}

job.resume(){
	require_moonraker_connect

	# DESCRIPTION: Resumes a paused print job
	# SYNTAX: moonraker job resume

	not_paused && 
		_error "Unable to resume print job - no print job paused" && 
		return 1

	printf "Resuming current print job... " 
	_post /printer/print/resume | jq --raw-output '.result'
}

job.cancel(){
	require_moonraker_connect

	local _job_status_output=$(job.status)
	local _job_status=$(echo "${_job_status_output}" | jq --raw-output '.printer')
	local _job_filename=$(echo "${_job_status_output}" | jq --raw-output '.filename')

	test $_job_status != 'printing' && 
		echo "No active print job to cancel" && 
		return 1

	confirm_action "Are you sure you want to cancel the print job ${_job_filename}?"

	test $? -ne 0 && 
		echo "Cancellation aborted" && 
		return

	# DESCRIPTION: Cancels a job currently being printed
	# SYNTAX: moonraker job cancel
	printf "Cancelling current print job... " 
	_post /printer/print/cancel | jq --raw-output '.result'
}

job.start(){
	require_moonraker_connect

	# DESCRIPTION: Start a new print job
	# SYNTAX: moonraker job start <filename>

	local filename="${1?-No filename provided}"

	gprintf "Starting print for %q... " "${filename}"

	_post /printer/print/start "filename=${filename}" | jq --raw-output '.result'

	#/printer/print/start?filename=test_print.gcode
}

job.watch(){
	require_moonraker_connect

	#trap 'screen_restore' SIGINT
	# DESCRIPTION: Watch job status data
	# SYNTAX: moonraker job watch <metrics>
	# EXAMPLE: moonraker job watch progress temperatures cpu logs
	#local watch_data="${@}"

	echo -e "Preparing to watch ${_egcmd_}moonraker job $@${_none_}"
	sleep 0.5
	return
	temp_terminal

	echo "Watching ${watch_data}..."
	sleep 2

	tput clear

	while true; do
		tput cup 0 0
		get_proc_stats_data
		show_cpu_usage
		#show_proc_stats_chart
		#show_system_memory_usage
		sleep ${GRAPH_UPDATE_INTERVAL:-3}
	done
}

get_proc_stats_data(){
	local tmp_filename="${1:-proc_stats.json}"

	#_get /machine/proc_stats | jq -rcM '.result' > $tmp_filename
	_get /machine/proc_stats  > $tmp_filename
}

show_cpu_usage(){
	local tmp_filename="${1:-proc_stats.json}"

	echo "CPU Usage"
	jq --from-file jq/filters/machine.proc_stats__cpu_usage.jq ${tmp_filename} | jp  -xy "..[time,cpu_usage]" -type line -width 100 -height 20
}

show_proc_stats_chart(){
	local tmp_filename="${1:-proc_stats.json}"

	# http://192.168.0.96:7125/machine/proc_stats
	# --raw-output --compact-output --monochrome-output
	# curl --silent http://192.168.0.96:7125/machine/proc_stats  | jq -rcM  '.result'
	# 
	# while true; do ps axu | jc --ps | jq '[.[] | select (.cpu_percent > 0.5)]' | jp -type bar -canvas full-escape -x ..pid -y ..cpu_percent; sleep 3; done
	#_get /machine/proc_stats | jq -rcM '.result' > $tmp_filename

	jq --raw-output '.result.system_cpu_usage | to_entries' ${tmp_filename}  |
		jp -type bar -canvas full-escape -x ..key -y ..value -height 6 -width 30
}

show_system_memory_usage(){
	local tmp_filename="${1:-proc_stats.json}"

	read mem_total mem_available mem_used <<< $(
		jq --raw-output '.result.system_memory | [.total, .available, .used] |@tsv' $tmp_filename
	)

	#local mem_unit_percents=$((100/${mem_total}))
	local mem_used_pc=$(bc <<< "scale=6; (100/${mem_total})*${mem_used}")

	printf "%15s: %s\n" "mem_total" "${mem_total}"
	printf "%15s: %s\n" "mem_available" "${mem_available}"
	printf "%15s: %s\n" "mem_used" "${mem_used}"
	#printf "%15s: %s\n" "mem_unit_percents" "${mem_unit_percents}"
	printf "%15s: %s\n" "mem_used_pc" "${mem_used_pc}"
}

show_print_progress(){
	# https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
	# https://github.com/m-sroka/bash-progress-bar
	echo "Print progress..."
}

is_printing() {
	local current_state=$(_get /printer/objects/query 'print_stats=state' | jq --raw-output '.result.status.print_stats.state')
	test $current_state == 'printing'
}

is_paused(){
	local current_state=$(_get /printer/objects/query 'pause_resume' | jq --raw-output '.result.status.pause_resume.is_paused')

	test $current_state == 'true'
}

not_paused(){
	is_paused
	test $? != 0
}


_debug "Arguments: $# - $*"

subcmd="${1:-help}"
subcmd_fn="${__module_name}.${subcmd}"

_debug "Subcommand: $subcmd"
shift


cmd_type=$(type -t "${subcmd_fn}")



if [[ ${cmd_type} == 'function' ]]; then
	eval ${subcmd_fn} ${@@Q}
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