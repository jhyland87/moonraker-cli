#!/usr/bin/env bash

#SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source ${CLI_DIR:=.}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/example.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # example.sh
__module_name=${__module_file%%.sh} # example
__moonraker_base_dir=$(realpath "${__module_dir}/../")
# echo ${__module_name^^} # EXAMPLE


# http://192.168.0.96:7125/printer/objects/list
declare -a show_objects
DEBUG=false

printer.description(){
	# DESCRIPTION: Description of this command
	echo "List, view and query printers" 1>&2
}

printer.help() {
	echo -e "${_bld_}${_dirtyyellow_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Test availability${_none_}"
	echo -e "     moonraker printer test"
	echo
}

[[ $# -eq 0 ]] && exit
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit

printer.connect(){
	echo "Switching to new printer"
}

show_printer_state() {
	require_moonraker_connect 

	local limit="${1:-20}"

	_get /api/printer | jq
	return
	curl ${API_HOST} \
		--request-target /api/printer \
		--request GET --silent |
			jq 
}

test_mjpg_streamer(){
	require_moonraker_connect

	port=${1:-8080}

	read exitcode http_code http_connect response_code size_download size_header time_appconnect time_connect time_total errormsg <<< $(
			curl \
				--silent \
				--output /dev/null \
				--write-out "%{exitcode}\t%{http_code}\t%{http_connect}\t%{response_code}\t%{size_download}\t%{size_header}\t%{time_appconnect}\t%{time_connect}\t%{time_total}\t%{errormsg}\n" \
				http://${MOONRAKER_HOST}:${port}/
		)

	test ${http_code} == 200
}

test_mjpg_streamer(){
	port=${1:-8080}

	read exitcode http_code http_connect response_code size_download size_header time_appconnect time_connect time_total errormsg <<< $(
			curl \
				--silent \
				--output /dev/null \
				--write-out "%{exitcode}\t%{http_code}\t%{http_connect}\t%{response_code}\t%{size_download}\t%{size_header}\t%{time_appconnect}\t%{time_connect}\t%{time_total}\t%{errormsg}\n" \
				http://${MOONRAKER_HOST}:${port}/
		)

	test ${http_code} == 200
}

test_mainsail(){
	port=${1:-4409}

	read exitcode http_code http_connect response_code size_download size_header time_appconnect time_connect time_total errormsg <<< $(
			curl \
				--silent \
				--output /dev/null \
				--write-out "%{exitcode}\t%{http_code}\t%{http_connect}\t%{response_code}\t%{size_download}\t%{size_header}\t%{time_appconnect}\t%{time_connect}\t%{time_total}\t%{errormsg}\n" \
				http://${MOONRAKER_HOST}:${port}/
		)

	test ${http_code} == 200
}

test_port(){
	nc -w 5 -z ${MOONRAKER_HOST} ${1?No port provided} &>/dev/null
}

test_ping(){
	ping -t 10 -i 1 -c 10 -nroq ${MOONRAKER_HOST} &>/dev/null
}

printer.test(){
	echo -e "${_bld_}Testing host ${MOONRAKER_HOST}${_none_}"
	printf "\t${_bld_}${_dirtyyellow_}%-20s${_none_} ... " "Pinging host"
	res_txt="${_green_}Success${_none_}"
	test_start_ts=$(_ts)
	test_ping 
	res_code=$?
	test_end_ts=$(_ts)
	test_duration=$(($test_end_ts-$test_start_ts))

	[[ ${res_code} -ne 0 ]] && res_txt="${_red_}FAILED${_none_}"

	printf "%-8b %b\n" "${res_txt}" "${_dim_}${_ital_}${test_duration}s${_none_}"

	[[ $res_code -ne 0 ]] && return 1

	declare -p | grep "_PORT" | tr -d "declare \-x"  | sed -E -e 's/_PORT=/\t/g' -e 's/"//g' | while read port_var; do
		read port_var port_num <<< $(echo $port_var)

		[[ ${port_var} == "MAINSAIL" && ${TEST_MAINSAIL} == false ]] && continue
		[[ ${port_var} == "FLUIDD" && ${TEST_FLUIDD} == false ]] && continue


		test_fn_type=$(type -t "test_${port_var@L}")

		printf "\t${_bld_}${_dirtyyellow_}%-20s${_none_} ... " "${port_var@L} (${port_num})" 

		res_txt="${_green_}Success${_none_}"
		test_start_ts=$(_ts)

		if [[ ${test_fn_type} == "function" ]]; then
			test_${port_var@L} ${port_num}
		else
			test_port ${port_num}
		fi
		res_code=$?

		test_end_ts=$(_ts)
		test_duration=$(($test_end_ts-$test_start_ts))

		[[ ${res_code} -ne 0 ]] && res_txt="${_red_}FAILED${_none_}"

		printf "%-8b %b\n" "${res_txt}" "${_dim_}${_ital_}${test_duration}s${_none_}"
	done
}

printer.info(){
	echo 'http://192.168.0.96:7125/printer/info'
}
_debug "Arguments: $# - $*"

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