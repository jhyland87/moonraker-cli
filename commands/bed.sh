#!/usr/bin/env bash

source ${CLI_DIR:=.}/includes/common.sh;
source ${CLI_DIR}/includes/colors.sh;
source ${CLI_DIR}/includes/logging.sh;
source ${CLI_DIR}/includes/prompts.sh;
source ${CLI_DIR}/includes/connect.sh;

__module_path=$(realpath "${BASH_SOURCE[0]}"); # /absolute/path/to/module/bed.sh
__module_dir=$(dirname "${__module_path}"); # /absolute/path/to/module
__module_file=$(basename ${__module_path}); # bed.sh
__module_name=${__module_file%%.sh}; # bed


bed.description(){
	# DESCRIPTION: Description of this command
	echo "This command deals with the print bed" 1>&2;
	#exit
}

bed.help() {
	echo -e "${_bld_}${_dirtyyellow_}${__module_name^^} COMMANDS${_none_}";
	echo;
	echo -e "  ${_bld_}${_ital_}${_blue_}View bed mesh${_none_}";
	echo -e "     moonraker bed mesh";
	echo;
	echo -e "  ${_bld_}${_ital_}${_blue_}Auto-level bed${_none_}";
	echo -e "     moonraker bed calibrate";
	echo;
	#exit
}

[[ $# -eq 0 ]] && exit;
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit;
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit;

show_printer_state() {
	#require_moonraker_api;
	
	local limit="${1:-20}";

	_get /api/printer | jq;
}

bed.mesh(){
	#require_moonraker_api;

	#_get /printer/objects/query 'bed_mesh' | jq --monochrome-output > "${TMP_DIR}/bed_mesh.tmp.json"

	read -r mesh_profile algorythm mesh_min mesh_max probed_matrix mesh_matrix mesh_highest mesh_lowest mesh_range std_deviation variance \
		<<< $(./jq/filters/bed.mesh__mesh_data.jq --raw-output "${TMP_DIR}/bed_mesh.tmp.json");

	if [[ $? -ne 0 ]]; then
		_error "Failed to parse bed mesh response with jq";
		exit 1;
	fi

	printFormat="${_none_}${_dim_}%18s:${_nodim_} ${_bold_}%-10s${_nbold_}";

	printf "${printFormat}" "Mesh profile" "${mesh_profile}";
	printf "${printFormat}\n" "Algorythm" "${algorythm}";
	printf "${printFormat}" "Min coordinates" "${mesh_min}";
	printf "${printFormat}\n" "Probed matrix" "${probed_matrix}";
	printf "${printFormat}" "Max coordinates" "${mesh_max}";
	printf "${printFormat}\n" "Mesh matrix" "${mesh_matrix}";
	printf "${printFormat}" "Probed range" "${mesh_range}";
	printf "${printFormat}\n" "Mesh highest" "${mesh_highest}";
	printf "${printFormat}" "Std deviation" "${std_deviation}";
	printf "${printFormat}\n" "Mesh lowest" "${mesh_lowest}";
	printf "${printFormat}" "Variance" "${variance}";
	printf "\n";

	#show_loader "Lading..." 5

	# Print the actual bed mesh render
	jq --raw-output '.result.status.bed_mesh.mesh_matrix | reverse | .[] | @csv' "${TMP_DIR}/bed_mesh.tmp.json" | ./includes/awk/hotbed_mesh_map.awk;
}

bed.calibrate(){
	curl http://192.168.0.96:7125 \
		--request POST \
		--request-target "/api/printer/command" \
		--silent \
		--json '{"commands":["BED_MESH_CALIBRATE"]}';
}

_debug "Arguments: $# - $*";

subcmd="${1:-help}";

subcmd_fn="${__module_name}.${subcmd}";

_debug "Subcommand: ${subcmd}";
_debug "Function: ${subcmd_fn}";
shift;

#cmd_type=$(type -t "${subcmd_fn}")

# Make sure the sumcommand is a defined function
if [[ $(type -t "${subcmd_fn}") != 'function' ]]; then
	_error "The command ${subcmd} is not a valid subcommand for ${__module_name}";
	exit 2;
fi

# Execute the full command
eval ${subcmd_fn} ${@@Q};