#!/usr/bin/env bash

source ${CLI_DIR}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh

# http://192.168.0.96:7125/printer/objects/list
declare -a show_objects
DEBUG=false

watch_description(){
	# DESCRIPTION: Description of this command
	echo "This command is for watching print status" 1>&2
}

watch_help() {
	echo -e "${_bld_}${_dirtyyellow_}PRINTER COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Test availability${_none_}"
	echo -e "     moonraker printer test"
	echo
}



_debug "Arguments: $# - $*"

#subcmd="${1:-help}"
#subcmd_fn="watch_${subcmd}"

#_debug "Subcommand: ${subcmd}"
#_debug "Function: ${subcmd_fn}"

echo -e "Executing ${_command_}moonraker $@${_none_}"
sleep 1

temp_terminal
term_width=`tput cols`
term_lines=`tput lines`

while true; do
	if [[ `tput cols` -ne ${term_width} || `tput lines` -ne ${term_lines} ]]; then
		term_width=`tput cols`
		term_lines=`tput lines`
		tput clear
	fi
	tput cup 0 0
	moonraker $@
	sleep 1;
done

#original_args=($@)
#shift

#echo "Args: ${original_args[@]}"

#cmd_type=$(type -t "${subcmd_fn}")

#if [[ ${cmd_type} == 'function' ]]; then
#	$subcmd_fn $*
#else
#	_error "The command ${subcmd} is not a valid function" && exit 1
#fi
