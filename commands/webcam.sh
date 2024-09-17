#!/usr/bin/env bash

source ${CLI_DIR:=.}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/webcam.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # webcam.sh
__module_name=${__module_file%%.sh} # example
# echo ${__module_name^^} # EXAMPLE

webcam.description(){
	# DESCRIPTION: Description of this command
	echo "This command for viewing the webcam" 1>&2
}

# echo ${LC_TERMINAL} ${TERM_PROGRAM}
# iTerm2 iTerm.app
webcam.help() {
	echo -e "${_bld_}${_dirtyyellow_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Get a single webcam snapshot${_none_}"
	echo -e "     moonraker example helloworld"
	echo -e "     ${_prompt_}# ${_eg_}Hello World${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Test availability${_none_}"
	echo -e "     moonraker example test"
	echo
}

[[ $# -eq 0 ]] && exit
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit

# View webcam snapshot
# TODO: Check that imgcat is present and that were using iterm
webcam.snapshot(){
	#curl "http://192.168.0.96:4408/webcam/"?action=snapshot

	${IMGCAT_BIN} --width ${1:-60px} --url "http://${MOONRAKER_HOST}:${MJPG_STREAMER_PORT:-8080}/?action=snapshot"

	#curl "http://${MOONRAKER_HOST}:${MJPG_STREAMER_PORT:-8080}" \
	#	  --request GET \
	#	  --connect-timeout ${MOONRAKER_TIMEOUT:-5} \
	#	  --silent \
	#	  --data "action=snapshot" 

	# http://192.168.0.96:8080/?action=stream
}

# Stream webcam
# TODO: Check that imgcat is present and that were using iterm
webcam.stream(){
	#curl "http://192.168.0.96:4408/webcam/"?action=snapshot
	echo "Starting webcam stream - ctrl+c to exit"
	sleep 2
	temp_terminal
	while true; do
		tput cup 0 0
		${IMGCAT_BIN} --width ${1:-60px} --url "http://${MOONRAKER_HOST}:${MJPG_STREAMER_PORT:-8080}/?action=snapshot"
		echo "Last update: $(_toISOtime)"
		sleep 1
	done

	#curl "http://${MOONRAKER_HOST}:${MJPG_STREAMER_PORT:-8080}" \
	#	  --request GET \
	#	  --connect-timeout ${MOONRAKER_TIMEOUT:-5} \
	#	  --silent \
	#	  --data "action=snapshot" 

	# http://192.168.0.96:8080/?action=stream
}

webcam.test(){
	show_printer_state
}

_debug "Arguments: $# - $*"

subcmd="${1:-help}"
subcmd_fn="${__module_name}.${subcmd}"

_debug "Subcommand: ${subcmd}"
_debug "Function: ${subcmd_fn}"
shift

#cmd_type=$(type -t "${subcmd_fn}")

# Make sure the sumcommand is a defined function
if [[ $(type -t "${subcmd_fn}") != 'function' ]]; then
	_error "The command ${subcmd} is not a valid subcommand for ${__module_name}" 
	exit 2
fi

# Execute the full command
eval ${subcmd_fn} ${@@Q}