#!/usr/bin/env bash

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

#[[ -z ${API_HOST} ]] && _err "No ${API_HOST} found" 1

#TEMP=$(getopt -o hl: --long help,list: \
#	        	-n 'wtf' -- "$@")

#[[ $? != 0 ]] && err "Getopt failed" 1

# Note the quotes around '$TEMP': they are essential!
#eval set -- "$TEMP"

# http://192.168.0.96:7125/printer/objects/list
declare -a show_objects
DEBUG=false

function printer_state {
	_get /printer/objects/query 'webhooks&virtual_sdcard&print_stats' |
		jq '.result.status | {message: last(.print_stats.message, .webhooks.state_message | select(. != "")), webhooks: .webhooks.state, printer: .print_stats.state, filename: .print_stats.filename, progress: .virtual_sdcard.progress} | with_entries(if .value == null or .value == "" then empty else . end)'
	return

	curl http://192.168.0.96:7125\
	  --request-target /printer/objects/query \
	  --request GET \
	  --silent \
	  --data 'webhooks&virtual_sdcard&print_stats' | 
	  	jq '.result.status | {message: last(.print_stats.message, .webhooks.state_message | select(. != "")), webhooks: .webhooks.state, printer: .print_stats.state, filename: .print_stats.filename, progress: .virtual_sdcard.progress} | with_entries(if .value == null or .value == "" then empty else . end)'
}

service.help() {
	echo "Help..." 1>&2
}

service.description(){
	# DESCRIPTION: Description of this command
	echo "This command is for managing services" 1>&2
	#exit
}

[[ $# -eq 0 ]] && exit
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit

show_print_state() {
	echo "show_print_state..."
}

require_moonraker_api

	declare -a jq_switches=()

	while true; do
	  case "$1" in
 	    -h | --help ) help; exit 0; shift ;;
	    -l | --list ) 
				show_objects+=(print_stats virtual_sdcard webhooks); 
				show_print_state=true
				shift ;;
	    -p | --printer ) show_objects+=(webhooks print_stats gcode_move); shift ;;
	    -h | --heaters ) show_objects+=(heaters gcode_move heater_bed); shift ;;
	    -m | --mcu ) show_objects+=(mcu 'mcu+nozzle_mcu' 'mcu+leveling_mcu' 'mcu+rpi'); shift ;;
	    -D | --sd | --sdcard ) show_objects+=(virtual_sdcard); 	shift ;;
	    -f | --filament | --filaments ) show_objects+=(filaments); shift ;;
	    -d | --display ) show_objects+=(display_status); shift ;;
	    -S | --sys | --system ) show_objects+=(system_stats); shift ;;
  		-v | --variable | --variables ) show_objects+=(save_variables); shift ;;
	    -c | --config | --configs ) show_objects+=(configfile); shift ;;
	    -r | --rpi ) show_objects+=('mcu+rpi'); shift ;;
	    -F | --fan | --fans ) show_objects+=('temperature_fan+chamber_fan' 'heater_fan+hotend_fan' 
	    	'output_pin+fan0' 'output_pin+fan1' 'output_pin+fan2' fan_feedback); shift ;;

	    -s | --stat | --status )  show_objects+=(webhooks print_stats gcode_move display_status
	    	system_stats mcu query_endstops motion_report heater_bed extruder toolhead); shift ;;

	    -E | --mesh | --bedmesh )  show_objects+=(bed_mesh heater_bed probe); shift ;;

	    -t | --temp | --temps | --temperatures ) 
				if [[ -z ${2} || ${2} =~ ^\- ]]; then
					show_objects+=('temperature_sensor+mcu_temp' 'temperature_sensor+chamber_temp' 
						'temperature_sensor+chamber_fan' heaters heater_bed)
				else
					sensor_list=$(echo $2 | awk 'BEGIN{RS=","}{ print("temperature_sensor+" $1) }' )
					show_objects+=(${sensor_list})
					shift
				fi
				shift ;;

			-P | --pin | --pins ) 
				if [[ -z ${2} || ${2} =~ ^\- ]]; then
					show_objects+=('output_pin+fan0' 'output_pin+fan1' 'output_pin+fan2')
				else
					pin_list=$(echo $2 | awk 'BEGIN{RS=","}{ print("output_pin+"$1) }' )
					show_objects+=(${pin_list}})
					shift
				fi
				shift ;;

			 -M | --macros | --macro ) 
				if [[ -z ${2} || ${2} =~ ^\- ]]; then
					show_objects+=('All Macros')
					# curl  --silent http://192.168.0.96:7125/printer/objects/list | jq -c '.result.objects[]  | select(contains("gcode_macro"))'
				else
					macro_list=$(echo $2 | awk 'BEGIN{RS=","}{ print("gcode_macro+"$1) }' )
					show_objects+=(${macro_list})
					shift
				fi
				shift ;;

	    -- ) shift; break ;;
	    * ) break ;;
	  esac
	done


#cmd_type=$(type -t "${subcmd_fn}")

# Make sure the sumcommand is a defined function
if [[ $(type -t "${subcmd_fn}") != 'function' ]]; then
	_error "The command ${subcmd} is not a valid subcommand for ${__module_name}" 
	exit 2
fi

# Execute the full command
eval ${subcmd_fn} ${@@Q}