#!/usr/bin/env bash

source ${CLI_DIR}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh

# http://192.168.0.96:7125/printer/objects/list
declare -a show_objects
DEBUG=false

status_description(){
	# DESCRIPTION: Description of this command
	echo "This command is for watching print status" 1>&2
}

status_help() {
	echo -e "${_bld_}${_dirtyyellow_}PRINTER COMMANDS${_none_}"
	echo
	echo -e "  ${_bld_}${_ital_}${_blue_}Test availability${_none_}"
	echo -e "     moonraker printer test"
	echo
}

status_fans(){
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

status_extruder(){
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

status_hotbed(){
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

status_mcutemp(){
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

status_chambertemp(){
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

status_chamberfan(){
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

status_chamberfanspeed(){
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



status_temps(){
	term_cols=$((`tput cols`-5))
	term_lines=$((`tput lines`/5-3))

	curl --silent 'http://192.168.0.96:7125/server/temperature_store' > temperature_store.json 
	status_extruder $term_cols $term_lines temperature_store.json
	_hr
	status_hotbed $term_cols $term_lines temperature_store.json
	_hr
	status_mcutemp $term_cols $term_lines temperature_store.json
	_hr
	status_chambertemp $term_cols $term_lines temperature_store.json
	#_hr
	#status_chamberfan $term_cols $term_lines #temperature_store.json
}


_debug "Arguments: $# - $*"

subcmd="${1:-help}"
subcmd_fn="status_${subcmd}"

#_debug "Subcommand: ${subcmd}"
#_debug "Function: ${subcmd_fn}"



_debug "Subcommand: ${subcmd}"
_debug "Function: ${subcmd_fn}"
shift

cmd_type=$(type -t "${subcmd_fn}")

if [[ ${cmd_type} == 'function' ]]; then
	${subcmd_fn} $*
else
	_error "The command ${subcmd} is not a valid command (${subcmd_fn} not found)" && exit 1
fi

