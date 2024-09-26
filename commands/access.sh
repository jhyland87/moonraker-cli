#!/usr/bin/env bash

source ${CLI_DIR:=.}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/access.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # access.sh
__module_name=${__module_file%%.sh} # access
__moonraker_base_dir=$(realpath "${__module_dir}/../")
# echo ${__module_name^^} # ACCESS


access.description(){
	# DESCRIPTION: Description of this command
	echo "This command is for managing jobs" 1>&2
}

access.help() {
	echo -e "${_helphead_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "  ${_egdesc_}Simple helloworld fn${_none_}"
	echo -e "     moonraker access helloworld"
	echo -e "     ${_prompt_}# ${_eg_}Hello World${_none_}"
	echo
	echo -e "  ${_egdesc_}Test availability${_none_}"
	echo -e "     moonraker access test"
	echo
}

[[ $# -eq 0 ]] && exit
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit


access.oneshot(){
	require_moonraker_connect 
	_get "/access/oneshot_token" | jq '.result'
}

access.apikey(){
	require_moonraker_connect 
	_get "/access/api_key" | jq '.result'
}

access.login(){
	require_moonraker_connect 
	_post "/access/login" "username=jhyland;password=68477f9;source=moonraker" | tee ~/.moonraker-auth | jq '.result | {username, token}' | yq e -P -
}

access.logout(){
	require_moonraker_connect 
	_post "/access/logout" | jq '.result'
}

access.id(){
	require_moonraker_connect 
	_get "/access/user" | jq '.result'
}

access.info(){
	require_moonraker_connect 
	_get "/access/info" | jq '.result'
}

access.users(){
	require_moonraker_connect 
	_get "/access/users/list" | jq '.result'
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

#cmd_type=$(type -t "${subcmd_fn}")

# Make sure the sumcommand is a defined function
if [[ $(type -t "${subcmd_fn}") != 'function' ]]; then
	_error "The command ${subcmd} is not a valid subcommand for ${__module_name}" 
	exit 2
fi

# Execute the full command
eval ${subcmd_fn} ${@@Q}