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
	local _term_width=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_width="${1:=$_term_width}"
	local term_lines="${2:=$_term_lines}"
	local sourcefile="$3"

	echo -e "CHAMBER_FAN TEMPERATURES\n"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
			--arg component "temperature_fan chamber_fan" \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line
	else
		
	curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
			--arg component "temperature_fan chamber_fan" \
			--arg datapoint temperatures | 
			jp -height $term_lines -width $term_width -xy "..[time,value]" -type line

	fi
}

status_extruder(){
	local _term_width=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_width="${1:=$_term_width}"
	local term_lines="${2:=$_term_lines}"
	local sourcefile="$3"

	#echo "term_width: $term_width"
	#echo "term_lines: $term_lines"
	#echo "sourcefile: $sourcefile"

	echo -e "EXTRUDER TEMPERATURE\n"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component extruder \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line
	else
		
	curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component extruder \
	 		--arg datapoint temperatures | 
	 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line


	 fi
}

status_hotbed(){
	local _term_width=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_width="${1:-$_term_width}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	echo -e "HOTBED TEMPERATURE\n"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component heater_bed \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line
	else
		
	curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component heater_bed \
	 		--arg datapoint temperatures | 
	 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line


	fi
}

status_mcutemp(){
	local _term_width=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_width="${1:-$_term_width}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	echo -e "MCU TEMPERATURE\n"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
		 	--arg component 'temperature_sensor chamber_temp' \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line
	else
		
	curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component 'temperature_sensor mcu_temp' \
	 		--arg datapoint temperatures | 
	 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line

	 fi
}

status_chambertemp(){
	local _term_width=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_width="${1:-$_term_width}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	echo -e "CHAMBER TEMPERATURE\n"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
		 	--arg component 'temperature_sensor chamber_temp' \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line
	else
		curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
			jq --monochrome-output \
				--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit 75 \
		 		--arg component 'temperature_sensor chamber_temp' \
		 		--arg datapoint temperatures | 
		 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line
	fi
}

status_chamberfan(){
	local _term_width=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))

	local term_width="${1:-$_term_width}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	echo -e "CHAMBER FAN TEMP\n"

	if [[ -f ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component 'temperature_fan chamber_fan' \
	 		--arg datapoint temperatures \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line
	else
		curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
			jq --monochrome-output \
				--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit 75 \
		 		--arg component 'temperature_fan chamber_fan' \
		 		--arg datapoint temperatures | 
		 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line
	fi		
}

status_chamberfanspeed(){
	local _term_width=$((`tput cols`-5))
	local _term_lines=$((`tput lines`/2-3))


	local term_width="${1:-$_term_width}"
	local term_lines="${2:-$_term_lines}"
	local sourcefile="$3"

	echo -e "CHAMBER FAN SPEED\n"

	if [[ -n ${sourcefile} ]]; then
		jq --monochrome-output \
			--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit 75 \
	 		--arg component 'temperature_fan chamber_fan' \
	 		--arg datapoint speeds \
	 		"${sourcefile}" | 
	 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line
	else
		curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
			jq --monochrome-output \
				--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit 75 \
		 		--arg component 'temperature_fan chamber_fan' \
		 		--arg datapoint speeds | 
		 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line
	fi	
}



status_temps(){
	term_width=$((`tput cols`-5))
	term_lines=$((`tput lines`/5-3))

	curl --silent 'http://192.168.0.96:7125/server/temperature_store' > temperature_store.json 
	status_extruder $term_width $term_lines temperature_store.json

	_hr
	status_hotbed $term_width $term_lines #temperature_store.json
	_hr
	status_mcutemp $term_width $term_lines #temperature_store.json
	_hr
	status_chambertemp $term_width $term_lines #temperature_store.json
	#_hr
	#status_chamberfan $term_width $term_lines #temperature_store.json
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

