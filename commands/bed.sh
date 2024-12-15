#!/usr/bin/env bash

source ${CLI_DIR:=.}/includes/common.sh
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

	_get /printer/objects/query 'bed_mesh' | jq --monochrome-output > "${TMP_DIR}/bed_mesh.tmp.json"

	read -r mesh_profile mesh_min mesh_max probed_matrix algorythm range mesh_matrix std_deviation variance <<< $(jq \
		'include "./jq/utils"; 
        (.result.status.bed_mesh.profile_name) as $profile |
        (.result.status.bed_mesh.profiles[$profile].mesh_params | [
			([float_to_int(.min_x), float_to_int(.min_y)] | join("/")), 
			([float_to_int(.max_x), float_to_int(.max_y)] | join("/")),
			([.x_count,.y_count] | join("x")),
			.algo
		]) as $mesh_params 
		| (.result.status.bed_mesh.mesh_matrix | [
			([.[][]] | sort_by(.) | .[-1]+(-.[0]) | trim_num(7)),
			(length as $x | .[0] | length as $y| [$x,$y] | join("x")),
            ([.[][]] | calc_std_deviation(true)),
            ([.[][]] | calc_variance(true))
		]) as $matrix_params 
		| [$profile, $mesh_params[], $matrix_params[]] | join(" ")' \
		--raw-output "${TMP_DIR}/bed_mesh.tmp.json")
	
	if [[ $? -ne 0 ]]; then
		_error "Failed to parse bed mesh response with jq"
		exit 1 
	fi

	printFormat="${_none_}${_dim_}%15s:${_nodim_} ${_bold_}%s${_nbold_}\n"

	printf "${printFormat}" "Mesh Profile" "${mesh_profile}"
	printf "${printFormat}" "Mesh min" "${mesh_min}"
	printf "${printFormat}" "Mesh max" "${mesh_max}"
	printf "${printFormat}" "Probed matrix" "${probed_matrix}"
	printf "${printFormat}" "Mesh matrix" "${mesh_matrix}"
	printf "${printFormat}" "Algorythm" "${algorythm}"
	printf "${printFormat}" "Range" "${range}"
	printf "${printFormat}" "Std. Deviation" "${std_deviation}"
	printf "${printFormat}" "Variance" "${variance}"

	jq --raw-output '.result.status.bed_mesh.mesh_matrix | reverse | .[] | @csv' "${TMP_DIR}/bed_mesh.tmp.json" | ./includes/awk/hotbed_mesh_map.awk
}

_debug "Arguments: $# - $*"

# for p in "$@"; do
# 	echo "${p}"
# done

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