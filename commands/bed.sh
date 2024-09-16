#!/usr/bin/env bash

#echo "[print] CLI_DIR: ${CLI_DIR:=./}"
source ${CLI_DIR:=./}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/bed.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # bed.sh
__module_name=${__module_file%%.sh} # bed



bed.description(){
	# DESCRIPTION: Description of this command
	echo "This command deals with the print bed" 1>&2
	#exit
}

bed.help() {
	echo -e "${_bld_}${_dirtyyellow_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}View bed mesh${_none_}"
	echo -e "     moonraker bed mesh"
	#echo -e "     ${_prompt_}# ${_eg_}Hello World${_none_}"
	echo
	#exit
}

[[ $# -eq 0 ]] && exit
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit 

# echo ${__module_name^^} # EXAMPLE

show_printer_state() {
	require_moonraker_connect 
	
	local limit="${1:-20}"

	_get /api/printer | jq
}

bed.mesh(){
	require_moonraker_connect 

	_get /printer/objects/query 'bed_mesh' > "${TMP_DIR}/bed_mesh.tmp.json"
	mesh_min=$(jq '.result.status.bed_mesh.mesh_matrix | flatten(1) | min' "${TMP_DIR}/bed_mesh.tmp.json")
	mesh_max=$(jq '.result.status.bed_mesh.mesh_matrix | flatten(1) | max' "${TMP_DIR}/bed_mesh.tmp.json")
	echo "Mesh min: ${mesh_min}"
	echo "Mesh max: ${mesh_max}"

	# curl --silent https://raw.githubusercontent.com/sgreben/jp/master/examples/mvrnorm.json| jp -xy '..[x,y]' -type hist2d -canvas full-bw -height 33 -width 66
}

_debug "Arguments: $# - $*"

for p in "$@"; do
	echo "${p}"
done

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