#!/usr/bin/env bash


#echo "[print] CLI_DIR: ${CLI_DIR}"
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

file.description(){
	# DESCRIPTION: Description of this command
	echo "This command is for managing files" 1>&2
	#exit
}

file.help(){
	echo -e "${_helphead_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "File/folder manipulation"
	echo
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


is_printing() {
	local current_state=$(_get /printer/objects/query 'print_stats=state' | \
		jq --raw-output '.result.status.print_stats.state')

	test $current_state == 'printing'
}

file.roots(){
	require_moonraker_connect

	# /server/files/roots

	_get /server/files/roots | jq --raw-output '.result'
}

file.list(){
	require_moonraker_connect

	local root_folder=${1:-gcodes}

	#_get /server/files/list "root=${root_folder}" | jq -L '../jq/' 'include "utils"; [.result[] | {path: .path, modified_ts:.modified, modified_date: (.modified|todate), size: (.size|bytes), permissions: .permissions}] | sort_by(.modified_ts) | reverse'

	_get /server/files/list 'root=gcodes' | 
		jq \
			--monochrome-output \
			--raw-output \
			-L "${__module_dir}/../jq" \
			--from-file "${__module_dir}/../jq/filters/file.print__recently_modified.jq"  \
			--arg limit 10 | json2table
}

file.print(){
	require_moonraker_connect

	is_printing && 
		echo "There is already a print in progress. You can cancel this print (moonraker print cancel) or wait for it to finish" 1>&2 && 
		return 1

	local gcode_filename=${1}

	if [[ ! ${gcode_filename} ]]; then
		declare -ga gcode_file_list

 		IFS=$'\n'

		read -e -d '' -a gcode_file_list <<< $(
			_get /server/files/list 'root=gcodes' | jq \
				--monochrome-output \
				--raw-output \
				-L '../jq/' \
				--from-file ./jq/filters/file.print__recently_modified.jq  \
				--arg limit 10 \
				--arg sort_by modified |
				jq --raw-output '.[].name' | sed -E -e 's/ /\\ /g' | 
				while read line; do
					printf "%b%-85s%b\n" "${_olivedrab_}" "${line}" "\e[0m"; 
				done)

		  # Capture any ctrl + x to allow the function to be aborted
	    # Also unset the trap within the trap execution..
	    trap 'echo -e "\033[0m\n\nCaptured SIGINT - quitting file.print"; trap - SIGINT; return 1' SIGINT

	    # Allow the destination folder to be selected from the list of folders
	    # found in stl_folders and stored in dest_dirs 
	    select file_name in ${gcode_file_list[@]} ; do
	        for r in $REPLY ; do
	            gcode_filename=${gcode_file_list[r - 1]}
	        done
	        [[ -n $REPLY ]] && break
	        #[[ -n $zipFile ]] && break
	    done

	    # undo any output formatting done in the above
	    echo ${_na}

	    # Cancel the above SIGINT trap so it won't interfere with stuff outside
	    # of this script.
	    trap - SIGINT

	    gcode_filename=$(_decolor "${gcode_filename}")
	fi

	[[ ! ${gcode_filename} ]] && 
		echo "No file seleted to print" 1>&2 && 
		return 1

	echo -n "Printing ${gcode_filename}... "

	_post /printer/print/start "filename=${gcode_filename}" | jq --raw-output '.result'
}

file.delete(){
	#echo "\$#: $#"
	#echo "\$@: $@"
	#echo "\$*: $*"
	#return
	require_moonraker_connect


	local force=false

	# Check if force is set, if not, prompt for confirmation
	if [[ $1 == "-f" || $1 == "--force" ]]; then
		force=true
		shift
	fi

	# Confirmation prompt, if necessary
	[[ $force != false ]] || 
		confirm_action "Are you sure you want to delete $# file(s)?" || 
		return 1

	#echo "Deleting ${#file_list[@]} file(s): ${file_list[@]}"

	for file in "$@"; do
		echo "Deleting ${file}.. [WIP]"
	done

	#echo "Deleting $# file(s): $@"
}

file.rm(){
	file.delete $@
}

#for p in "$@"; do
#	echo "${p}"
#done



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