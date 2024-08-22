#!/usr/bin/env bash

#echo "[print] CLI_DIR: ${CLI_DIR}"
source ${CLI_DIR}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh

#export -p

declare -r cmd_file=$(basename $0 | tr -d '.sh')


file_description(){
	# DESCRIPTION: Description of this command
	echo "This command is for managing files" 1>&2
}

file_help(){
	echo -e "${_bld_}${_dirtyyellow_}FILE COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}List files${_none_}"
	echo -e "    moonraker file list [${_ul_}directory${_ulx_}]"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Delete file(s)/folder(s)${_none_}"
	echo -e "    moonraker file rm ${_ul_}file_1.gcode${_ulx_} [${_ul_}dir/file_2.gcode${_ulx_} ${_ul_}dir/subdir${_ulx_}]"
	echo
}

is_printing() {
	local current_state=$(_get /printer/objects/query 'print_stats=state' | jq --raw-output '.result.status.print_stats.state')
	test $current_state == 'printing'
}

file_roots(){

	# /server/files/roots

	_get /server/files/roots | jq --raw-output '.result'
}

file_list(){
	local root_folder=${1:-gcodes}

	#_get /server/files/list "root=${root_folder}" | jq -L '../jq/' 'include "utils"; [.result[] | {path: .path, modified_ts:.modified, modified_date: (.modified|todate), size: (.size|bytes), permissions: .permissions}] | sort_by(.modified_ts) | reverse'

	_get /server/files/list 'root=gcodes' | jq \
		--monochrome-output \
		--raw-output \
		-L '../jq/' \
		--from-file ./jq/filters/file.print__recently_modified.jq  \
		--arg limit 10 \
		--arg sort_by modified | jq '.[].name'
}



file_print(){
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
	    trap 'echo -e "\033[0m\n\nCaptured SIGINT - quitting file_print"; trap - SIGINT; return 1' SIGINT

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



_debug "Arguments: $# - $*"

subcmd="$1"

_debug "Subcommand: $subcmd"
shift


cmd_type=$(type -t "${cmd_file}_${subcmd}")



if [[ ${cmd_type} == 'function' ]]; then
	${cmd_file}_$subcmd $*
else
	_error "The command ${subcmd} is not a valid subcommand for ${cmd_file}" 1
fi