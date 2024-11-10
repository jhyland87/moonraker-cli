#!/usr/bin/env bash
source ${CLI_DIR:=.}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

# http://192.168.0.96:7125/printer/objects/list
__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/example.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # example.sh
__module_name=${__module_file%%.sh} # example
__moonraker_base_dir=$(realpath "${__module_dir}/../")
# echo ${__module_name^^} # EXAMPLE

temp_header_fmt="%b%s\e[0m\n\n"
graph_limit=500 #75

status.description(){
	# DESCRIPTION: Description of this command
	echo "This command is for watching print status" 1>&2
}

status.help() {
	echo -e "${_bld_}${_dirtyyellow_}${__module_name^^} COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Show all temps${_none_}"
	echo -e "     moonraker status temps"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Show fan status${_none_}"
	echo -e "     moonraker status fans"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Show extruder temp${_none_}"
	echo -e "     moonraker status extruder"
	echo
}

status.status(){
	echo "test"
	status.help
}

[[ $# -eq 0 ]] && 1=help
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit

status.fans(){
	require_moonraker_connect

	local _term_cols=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_cols="${1:=$_term_cols}"
	local term_lines="${2:=$_term_lines}"
	local sourcefile="$3"

	_h2 "CHAMBER_FAN TEMPERATURES"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit ${graph_limit:-75} \
			--arg component "temperature_fan chamber_fan" \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	else
		
	curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
		jq --monochrome-output \
			--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit ${graph_limit:-75} \
			--arg component "temperature_fan chamber_fan" \
			--arg datapoint temperatures | 
			jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line

	fi
}

status.socket(){
	require_moonraker_connect
}


status.extruder(){
	require_moonraker_connect
	
	local _term_cols=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_cols="${1:=$_term_cols}"
	local term_lines="${2:=$_term_lines}"
	local sourcefile="$3"

	#echo "term_cols: $term_cols"
	#echo "term_lines: $term_lines"
	#echo "sourcefile: $sourcefile"

	# extruder: red, bed: blue, chamber: purple, mcu: orange
	
	#currentTemp=$(cat "${sourcefile}"| jq '.result.["temperature_sensor mcu_temp"].temperatures[-1]')
	#printf "%b%s\e[0m (%s)\n\n" "\033[38;2;255;82;82;1;4m" "EXTRUDER TEMPERATURE" "${currentTemp}"	
	#echo -en "\033[38;2;255;82;82m"
	if [[ -f ${sourcefile} ]]; then
		graph_data=$(
			jq --monochrome-output \
				--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit ${graph_limit:-75} \
				--arg component extruder \
				--arg datapoint temperatures \
				"${sourcefile}" 
		)
	else
		graph_data=$(
			curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
				jq --monochrome-output \
					--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
					--arg limit ${graph_limit:-75} \
					--arg component extruder \
					--arg datapoint temperatures
			)
	 fi

	current_value=$(printf "$graph_data" | jq '.[-1].value')
	last_value=$(printf "$graph_data" | jq '.[-2].value')
	
	val_diff_ico="\u25B8"
	# ▸ \u25B8
	# ⬩ \u2B29
	val_diff_percent=$(_get_percent "${current_value}" "${last_value}")
	if _greater_than $current_value $last_value; then
		#val_diff_ico="\u25B2"
		val_diff_ico="\u25B4"
	elif _less_than $current_value $last_value; then
		#val_diff_ico="\u25BC"
		val_diff_ico="\u25BE"
	fi

	printf "%b%s\e[0m %s °C \e[0;38m(%b %s)\e[0m\n\n" "\033[38;2;255;82;82;1;4m" \
		"EXTRUDER TEMPERATURE" \
		"${current_value}" \
		"${val_diff_ico}" \
		"${val_diff_percent}"

	# UP: \u25B2
	# DOWN: \u25BC
	
	echo "$graph_data" | jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
}

status.hotbed(){
	require_moonraker_connect
	
	local _term_cols=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_cols="${1:-$_term_cols}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	if [[ -f ${sourcefile} ]]; then
		graph_data=$(
			jq --monochrome-output \
				--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit ${graph_limit:-75} \
				--arg component heater_bed \
				--arg datapoint temperatures \
				"${sourcefile}" 
		)
	else
		graph_data=$(
			curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
				jq --monochrome-output \
					--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
					--arg limit ${graph_limit:-75} \
					--arg component heater_bed \
					--arg datapoint temperatures 
		)
	fi

	current_value=$(printf "$graph_data" | jq '.[-1].value')
	last_value=$(printf "$graph_data" | jq '.[-2].value')
	val_diff_percent=$(_get_percent "${current_value}" "${last_value}")

	val_diff_ico="\u25B8"
	if _greater_than $current_value $last_value; then
		val_diff_ico="\u25B4"
	elif _less_than $current_value $last_value; then
		val_diff_ico="\u25BE"
	fi

	printf "%b%s\e[0m %s °C \e[0;38m(%b %s)\033[K\e[0m\n\n" "\033[38;2;32;176;255;1;4m" \
		"HOTBED TEMPERATURE" \
		"${current_value}" \
		"${val_diff_ico}" \
		"${val_diff_percent}"

	echo "${graph_data}" | jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
}

status.mcutemp(){
	require_moonraker_connect
	
	local min_cols=130 min_lines=7 max_lines=12
	local _term_cols=$((`tput cols`-5))  _term_lines=$((`tput lines`/2-3))

	local term_cols="${1:-$_term_cols}"
	local term_lines="${2:-$_term_lines}"

	if [[ ${term_cols} -lt ${min_cols} ]]; then
		term_cols=$min_cols
	fi

	if [[ ${term_lines} -lt ${min_lines} ]]; then
		term_lines=$min_lines
	elif [[ ${term_lines} -gt ${max_lines} ]]; then
		term_lines=$max_lines
	fi

	if [[ -f ${sourcefile} ]]; then
		graph_data=$(
			jq --monochrome-output \
				--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit ${graph_limit:-75} \
				--arg component 'temperature_sensor chamber_temp' \
				--arg datapoint temperatures \
				"${sourcefile}"
		)	
	else
		graph_data=$(
			curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
				jq --monochrome-output \
					--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
					--arg limit ${graph_limit:-75} \
					--arg component 'temperature_sensor mcu_temp' \
					--arg datapoint temperatures
		)
	fi

	current_value=$(printf "$graph_data" | jq '.[-1].value')
	last_value=$(printf "$graph_data" | jq '.[-2].value')
	val_diff_percent=$(_get_percent "${current_value}" "${last_value}")

	val_diff_ico="\u25B8"
	if _greater_than $current_value $last_value; then
		val_diff_ico="\u25B4"
	elif _less_than $current_value $last_value; then
		val_diff_ico="\u25BE"
	fi

	printf "%b%s\e[0m %s °C \e[0;38m(%b %s)\033[K\e[0m\n\n" "\033[38;2;214;118;0;1;4m" \
		"MCU TEMPERATURE" \
		"${current_value}" \
		"${val_diff_ico}" \
		"${val_diff_percent}"

	echo "${graph_data}" | jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
}

status.chambertemp(){
	require_moonraker_connect
	
	local _term_cols=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_cols="${1:-$_term_cols}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	if [[ -f ${sourcefile} ]]; then
		graph_data=$(
			jq --monochrome-output \
				--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit ${graph_limit:-75} \
				--arg component 'temperature_sensor chamber_temp' \
				--arg datapoint temperatures \
				"${sourcefile}" 
		)
	else
		graph_data=$(
			curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
				jq --monochrome-output \
					--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
					--arg limit ${graph_limit:-75} \
					--arg component 'temperature_sensor chamber_temp' \
					--arg datapoint temperatures

		)
	fi

	current_value=$(printf "$graph_data" | jq '.[-1].value')
	last_value=$(printf "$graph_data" | jq '.[-2].value')
	val_diff_percent=$(_get_percent "${current_value}" "${last_value}")

	val_diff_ico="\u25B8"
	if _greater_than $current_value $last_value; then
		val_diff_ico="\u25B4"
	elif _less_than $current_value $last_value; then
		val_diff_ico="\u25BE"
	fi

	printf "%b%s\e[0m %s °C \e[0;38m(%b %s)\033[K\e[0m\n\n" "\033[38;2;131;14;227;1;4m" \
		"CHAMBER TEMPERATURE" \
		"${current_value}" \
		"${val_diff_ico}" \
		"${val_diff_percent}"

	echo "${graph_data}" | jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
}

status.chamberfan(){
	require_moonraker_connect
	
	local _term_cols=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_cols="${1:-$_term_cols}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	#printf "${temp_header_fmt}" "\033[38;2;60;194;90;1;4m" "CHAMBER FAN TEMPERATURE"

	if [[ -f ${sourcefile} ]]; then
		graph_data=$(
			jq --monochrome-output \
				--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit ${graph_limit:-75} \
				--arg component 'temperature_fan chamber_fan' \
				--arg datapoint temperatures \
				"${sourcefile}"
			)
	else
		graph_data=$(
			curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
				jq --monochrome-output \
					--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
					--arg limit ${graph_limit:-75} \
					--arg component 'temperature_fan chamber_fan' \
					--arg datapoint temperatures

			) 	
	fi

	current_value=$(printf "$graph_data" | jq '.[-1].value')
	last_value=$(printf "$graph_data" | jq '.[-2].value')
	val_diff_percent=$(_get_percent "${current_value}" "${last_value}")

	val_diff_ico="\u25B8"
	if _greater_than $current_value $last_value; then
		val_diff_ico="\u25B4"
	elif _less_than $current_value $last_value; then
		val_diff_ico="\u25BE"
	fi

	printf "%b%s\e[0m %s °C \e[0;38m(%b %s)\033[K\e[0m\n\n" "\033[38;2;60;194;90;1;4m" \
		"CHAMBER FAN TEMPERATURE" \
		"${current_value}" \
		"${val_diff_ico}" \
		"${val_diff_percent}"

	echo "${graph_data}" | jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line

}

status.chamberfanspeed(){
	require_moonraker_connect
	
	local min_cols=130 min_lines=7 
	local _term_cols=$((`tput cols`-5))  _term_lines=$((`tput lines`/2-3))

	local term_cols="${1:-$_term_cols}"
	local term_lines="${2:-$_term_lines}"

	if [[ ${term_cols} -lt ${min_cols} ]]; then
		term_cols=$min_cols
	fi

	if [[ ${term_lines} -lt ${min_lines} ]]; then
		term_lines=$min_lines
	fi

	local sourcefile="$3"

	_h2 "CHAMBER FAN SPEED"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit ${graph_limit:-75} \
	 		--arg component 'temperature_fan chamber_fan' \
	 		--arg datapoint speeds \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	else
		curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
			jq --monochrome-output \
				--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit ${graph_limit:-75} \
		 		--arg component 'temperature_fan chamber_fan' \
		 		--arg datapoint speeds | 
		 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	fi	
}

status.temps(){
	require_moonraker_connect
	
	term_cols=$((`tput cols`-5))
	term_lines=$((`tput lines`/5-3))

	curl --silent 'http://192.168.0.96:7125/server/temperature_store' > temperature_store.json 
	status.extruder $term_cols $term_lines temperature_store.json
	_hr
	status.hotbed $term_cols $term_lines temperature_store.json
	_hr
	status.mcutemp $term_cols $term_lines temperature_store.json
	_hr
	status.chambertemp $term_cols $term_lines temperature_store.json
	_hr
	status.chamberfan $term_cols $term_lines #temperature_store.json
}


status.show(){
	require_moonraker_connect
	
	echo "Checking status"
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