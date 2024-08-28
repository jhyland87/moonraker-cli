#!/usr/bin/env bash

#echo "[print] CLI_DIR: ${CLI_DIR}"
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



#[[ -z ${API_HOST} ]] && _error "No ${API_HOST} found" 1
#echo "API_HOST: ${API_HOST}"



# Note the quotes around '$TEMP': they are essential!
#eval set -- "$TEMP"

# http://192.168.0.96:7125/printer/objects/list
declare -a show_objects
DEBUG=false

macro.description(){
	# DESCRIPTION: Description of this command
	confirm_action
	echo "This command is for managing jobs" 1>&2
}

macro.help() {
	echo "Help..." 1>&2

	declare -pf  | grep -E -A4  '^macro.' # | sed -E 's/^declare .* macro.//g'
}


macro.help(){
	echo -e "${_bld_}${_dirtyyellow_}MACRO COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}List macros${_none_}"
	echo -e "    moonraker macro list"
	echo
	echo -e "  ${_ital_}${_bld_}${_blue_}Execute macro${_none_}"
	echo -e "    moonraker macro execute ${_ul_}macro_name${_ulx_} [${_ul_}macro_params${_ulx_}]"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Examples${_none_}"
	echo -e "    moonraker macro execute FIRMWARE_RESTART"
	echo -e "    moonraker macro execute SET_TEMPERATURE_FAN_TARGET TEMPERATURE_FAN=chamber_fan TARGET=35"
	echo -e "    moonraker macro execute -- SET_TEMPERATURE_FAN_TARGET TEMPERATURE_FAN=chamber_fan TARGET=35"
	echo
}


macro.list(){
	require_moonraker_connect

	#local object_list=$(_get /printer/objects/list)

	#curl  --silent http://192.168.0.96:7125/printer/objects/list | jq -c '.result.objects[] | select(contains("gcode_macro")) | sub("gcode_macro "; "")'
	# curl --silent http://192.168.0.96:7125 --request GET --request-target /printer/objects/list
	# curl --silent http://192.168.0.96:7125 --request GET --request-target printer/objects/list
	#set -x
	local _macros=$(_get "/printer/objects/list" | jq --raw-output '.result.objects[] | select(contains("gcode_macro")) | sub("gcode_macro "; "")')

	local max_len=29 #$( _get_widest_len_from_list "$_macros")
	#echo "MACROS: ${_macros}" 1>&2
	#echo "max_len: ${max_len}" 1>&2



	local i=0
	local col_width=$(($max_len+3))
	local max_cols=4

	for m in $_macros; do
		let 'i+=1'
		printf "%-${col_width}s " "${m}"
		#echo -e "${m}\t"

		if [[ $i -eq $max_cols ]]; then
			echo
			i=0
		fi
	done

	#  --raw-output 
	# --color-output
	#set +x
}


# curl http://192.168.0.96:7125 --request GET  --request-target  /printer/objects/query --data 'webhooks&virtual_sdcard&print_stats' --silent 
# curl http://192.168.0.96:7125 --request GET  --request-target  /printer/objects/query --data 'webhooks=state,state_message&print_stats=state' --silent  | jq '.result'


is_printing() {
	local current_state=$(_get /printer/objects/query 'print_stats=state' | jq --raw-output '.result.status.print_stats.state')
	test $current_state == 'printing'
}


_debug "Arguments: $# - $*"

subcmd="${1:-list}"
subcmd_fn="${__module_name}.${subcmd}"

_debug "Subcommand: $subcmd"
shift


cmd_type=$(type -t "${subcmd_fn}")



if [[ ${cmd_type} == 'function' ]]; then
	eval ${subcmd_fn} ${@@Q}
else
	_error "The command ${subcmd} is not a valid function" 1
fi


#TEMP=$(getopt -o hlsSTRP: --long help,list,status,stop,start,pause,resume: -n 'wtf' -- "$*")

#[[ $? != 0 ]] && _error "Getopt failed" 1

#while true; do
#	case "$1" in
# 		-h | --help ) help; exit 0; shift ;;
#	  -s | --status ) show_print_state; exit 0; shift ;;
#		-- ) shift; break ;;
#	  * ) break ;;
#	esac
#done