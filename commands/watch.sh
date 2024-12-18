#!/usr/bin/env bash

source ${CLI_DIR:=.}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/example.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # example.sh
__module_name=${__module_file%%.sh} # example
__moonraker_base_dir=$(realpath "${__module_dir}/../")
# echo ${__module_name^^} # EXAMPLE


watch.description(){
	# DESCRIPTION: Description of this command
	echo "This command is for watching print status" 1>&2
}

watch.help() {
	echo -e "${_bld_}${_dirtyyellow_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Test availability${_none_}"
	echo -e "     moonraker ${__module_name} test"
	echo
}

[[ $# -eq 0 ]] && exit
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit


_debug "Arguments: $# - $*"

require_moonraker_api

#subcmd="${1:-help}"
#subcmd_fn="${__module_name}.${subcmd}"

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
	eval moonraker ${@@Q}
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
