#!/usr/bin/env bash

source ${CLI_DIR}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/example.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # example.sh
__module_name=${__module_file%%.sh} # example
# echo ${__module_name^^} # EXAMPLE

show_printer_state() {
	require_moonraker_connect 
	
	local limit="${1:-20}"

	_get /api/printer | jq
}

example.description(){
	# DESCRIPTION: Description of this command
	echo "This command is for managing jobs" 1>&2
}

example.helloworld(){
	echo "Hello world from ${__module_name} (${__module_path})"
}

example.test(){
	show_printer_state
}

example.help() {
	echo -e "${_bld_}${_dirtyyellow_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Simple helloworld fn${_none_}"
	echo -e "     moonraker example helloworld"
	echo -e "     ${_prompt_}# ${_eg_}Hello World${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Test availability${_none_}"
	echo -e "     moonraker example test"
	echo
}

_debug "Arguments: $# - $*"

# Default subcommand
subcmd="${1:-help}"

subcmd="${subcmd%\'}"
subcmd="${subcmd#\'}"
subcmd_fn="${__module_name}.${subcmd}"

_debug "Subcommand: ${subcmd}"
_debug "Function: ${subcmd_fn}"
shift

cmd_type=$(type -t "${subcmd_fn}")

if [[ ${cmd_type} == 'function' ]]; then
	eval ${subcmd_fn} $*
else
	_error "The command ${subcmd_fn} is not a valid function" && exit 1
fi
