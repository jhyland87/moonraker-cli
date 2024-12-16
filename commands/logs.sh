#!/usr/bin/env bash

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
__moonraker_base_dir=$(realpath "${__module_dir}/../")

#cwd=$(dirname "${BASH_SOURCE[0]}")

#declare -r cmd_file=$(basename ${BASH_SOURCE[0]} | tr -d '.sh')

logs.description(){
	# DESCRIPTION: Description of this command
	echo "View/search/rotate/delete logs" 1>&2
	#exit
}

logs.help(){
	echo -e "${_helphead_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "Logfile manager"
	echo
    return
	echo -e "EXAMPLES:"
	echo -e "  ${_egdesc_}List files${_none_}"
	echo -e "  ${_prompt_}\$${_none_} ${_egcmd_}moonraker file list [${_ul_}directory${_ulx_}]${_none_}"
	echo -e "  ${_egres_}# List of contents in directory${_none_}"

	echo
	echo -e "  ${_egdesc_}Delete file(s)/folder(s)${_none_}"
	echo -e "  ${_prompt_}\$${_none_} ${_egcmd_}moonraker file delete ${_ul_}file_1.gcode${_ulx_} [${_ul_}dir/file_2.gcode${_ulx_} ${_ul_}dir/subdir${_ulx_}]${_none_}"
	echo -e "  ${_egres_}# Will prompt for confirmation${_none_}"
	echo
	echo -e "  ${_prompt_}\$${_none_} ${_egcmd_}moonraker file delete -f ${_ul_}file_1.gcode${_ulx_} [${_ul_}dir/file_2.gcode${_ulx_} ${_ul_}dir/subdir${_ulx_}]${_none_}"
	echo -e "  ${_egres_}# Will ${_ul_}not${_ulx_} prompt for confirmation${_none_}"
	echo
	#exit
}

[[ $# -eq 0 ]] && exit
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit


logs.list(){
	require_moonraker_connect

	_get /server/files/list root=logs | 
		jq  --monochrome-output --raw-output \
    		-L './jq/' \
    		--from-file ./jq/filters/file.print__recently_modified.jq \
    		--arg limit 5 | 
    	jq --monochrome-output --raw-output \
			-L './jq/' \
			--from-file ./jq/modifiers/array_of_objects_to_csv.jq \
			--arg output tsv | 
		column -ts $'\t' | 
		sed -e $'1s/^/\e[3m/' -e $'1s/$/\e[0m/'		
}

logs.download(){
	logfile=${1:-moonraker.log}
	# /server/files/{root}/{filename}
	_get /server/files/logs/${logfile}
}

_debug "Arguments: $# - $*"

subcmd="${1:-help}"

#subcmd=${1}
subcmd_fn="${__module_name}.${subcmd}"

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