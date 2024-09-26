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

_commands_dir="${__moonraker_base_dir}/commands"


help.description(){
	# DESCRIPTION: Description of this command
	echo "Help menu" 1>&2
	#exit
}


help.help(){
	echo -e "${_helphead_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "Not much..."
	echo
}

subcmd=${1:-help}
[[ $subcmd == 'description' ]] && eval ${__module_name}.description && exit
[[ $subcmd == 'help' ]] && eval ${__module_name}.help && exit

listcommands(){
	ls -1 ${_commands_dir} | sed -E 's/\.sh$//g' | grep -v example
}

help.commands(){
	echo "Available commands:" | tr '[:lower:]' '[:upper:]'
	#_h1 "available cmds:"
	listcommands | while read cmd; do
		printf "    %b%-10s%b\t" "${_command_}" "${cmd}" "${_none_}"
		bash ${_commands_dir}/$cmd.sh description
	done

	echo
	echo "For help on a specific command"
	echo -e "    ${_commandDim_}moonraker${_none_} ${_command_}command${_none_} ${_ital_}help${_none_}"
	echo
}

#echo -e "${_h1_}Available commands${_none_}"
#echo -e "${_h2_}Available commands${_none_}"
#echo -e "${_h3_}Available commands${_none_}"



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