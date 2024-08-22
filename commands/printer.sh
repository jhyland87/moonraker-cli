#!/usr/bin/env bash

source ${CLI_DIR}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh

# http://192.168.0.96:7125/printer/objects/list
declare -a show_objects
DEBUG=false

printer_description(){
	# DESCRIPTION: Description of this command
	echo "This command is for managing jobs" 1>&2
}

printer_help() {
	echo -e "${_bld_}${_dirtyyellow_}PRINTER COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Test availability${_none_}"
	echo -e "     moonraker printer test"
	echo
}

show_printer_state() {
	local limit="${1:-20}"

	_get /api/printer | jq
	return
	curl ${API_HOST} \
		--request-target /api/printer \
		--request GET --silent |
			jq 
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

printer_test(){
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

printer_info(){
	http://192.168.0.96:7125/printer/info
}
_debug "Arguments: $# - $*"

subcmd="${1:-help}"

_debug "Subcommand: ${subcmd}"
_debug "Function: printer_${subcmd}"
shift

cmd_type=$(type -t "printer_${subcmd}")

if [[ ${cmd_type} == 'function' ]]; then
	printer_$subcmd $*
else
	_error "The command ${subcmd} is not a valid function" && exit 1
fi
