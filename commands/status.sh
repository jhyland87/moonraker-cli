#!/usr/bin/env bash


if [[ $1 == '--description' ]]; then
	echo "Status related commands"
	exit 
fi

source ${CLI_DIR}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

# http://192.168.0.96:7125/printer/objects/list
__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/example.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # example.sh
__module_name=${__module_file%%.sh} # example
# echo ${__module_name^^} # EXAMPLE


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
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
			--arg component "temperature_fan chamber_fan" \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	else
		
	curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
			--arg component "temperature_fan chamber_fan" \
			--arg datapoint temperatures | 
			jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line

	fi
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

	_h2 "EXTRUDER TEMPERATURE"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component extruder \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	else
		
		curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
			jq --monochrome-output \
				--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit 75 \
				--arg component extruder \
				--arg datapoint temperatures | 
				jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line


	 fi
}

status.hotbed(){
	require_moonraker_connect
	
	local _term_cols=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_cols="${1:-$_term_cols}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	_h2 "HOTBED TEMPERATURE"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component heater_bed \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	else
		
	curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component heater_bed \
	 		--arg datapoint temperatures | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line


	fi
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

	_h2 "MCU TEMPERATURE"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
		 	--arg component 'temperature_sensor chamber_temp' \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	else
		
	curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component 'temperature_sensor mcu_temp' \
	 		--arg datapoint temperatures | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line

	 fi
}

status.chambertemp(){
	require_moonraker_connect
	
	local _term_cols=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_cols="${1:-$_term_cols}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	_h2 "CHAMBER TEMPERATURE"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
		 	--arg component 'temperature_sensor chamber_temp' \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	else
		curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
			jq --monochrome-output \
				--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit 75 \
		 		--arg component 'temperature_sensor chamber_temp' \
		 		--arg datapoint temperatures | 
		 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	fi
}

status.chamberfan(){
	require_moonraker_connect
	
	local _term_cols=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_cols="${1:-$_term_cols}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	_h2 "CHAMBER FAN TEMP"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component 'temperature_fan chamber_fan' \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	else
		curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
			jq --monochrome-output \
				--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit 75 \
		 		--arg component 'temperature_fan chamber_fan' \
		 		--arg datapoint temperatures | 
		 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	fi		
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
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component 'temperature_fan chamber_fan' \
	 		--arg datapoint speeds \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	else
		curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
			jq --monochrome-output \
				--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit 75 \
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
	#_hr
	#status.chamberfan $term_cols $term_lines #temperature_store.json
}


status.show(){
	require_moonraker_connect
	
	echo "Checking status"
}

_debug "Arguments: $# - $*"

subcmd="${1:-show}"
subcmd_fn="${__module_name}.${subcmd}"

_debug "Subcommand: ${subcmd}"
_debug "Function: ${subcmd_fn}"
shift

cmd_type=$(type -t "${subcmd_fn}")

if [[ ${cmd_type} == 'function' ]]; then
	eval ${subcmd_fn} ${@@Q}
else
	_error "The command ${subcmd} is not a valid command (${subcmd_fn} not found)" && exit 1
fi

