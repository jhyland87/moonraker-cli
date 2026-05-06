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

chart_min=100
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

[[ $# -eq 0 ]] && set -- help
[[ $1 == 'description' ]] && eval ${__module_name}.description && exit
[[ $1 == 'help' ]] && eval ${__module_name}.help && exit

status.fans(){
	require_moonraker_api

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

	curl --silent "${MOONRAKER_API_BASE}/server/temperature_store" | \
		jq --monochrome-output \
			--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
			--arg limit ${graph_limit:-75} \
			--arg component "temperature_fan chamber_fan" \
			--arg datapoint temperatures |
			jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line

	fi
}

status.socket(){
	require_moonraker_api
}


status.extruder(){
	require_moonraker_api

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
			curl --silent "${MOONRAKER_API_BASE}/server/temperature_store" | \
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

	#echo "$graph_data" | jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	echo "$graph_data" | bash "${CLI_DIR}/includes/chart.sh" \
		-height $term_lines \
		-width $term_cols \
		-timefmt MM:SS \
    -line-color yellow \
    -label-color cyan \
    -time-color magenta \
    -axis-color light-gray
		# -min $chart_min
}

status.hotbed(){
	require_moonraker_api

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
			# curl --silent "http://192.168.0.96:7125/server/temperature_store" |
			curl --silent "${MOONRAKER_API_BASE}/server/temperature_store" |
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

	#echo "${graph_data}" | jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	echo "$graph_data" | bash "${CLI_DIR}/includes/chart.sh" \
		-height $term_lines \
		-width $term_cols \
		-timefmt MM:SS \
    -line-color yellow \
    -label-color cyan \
    -time-color magenta \
    -axis-color light-gray
		# -min $chart_min
}

status.mcutemp(){
	require_moonraker_api

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
			curl --silent "${MOONRAKER_API_BASE}/server/temperature_store" | \
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

	#echo "${graph_data}" | jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	#echo "${graph_data}" | bash ${CLI_DIR}/includes/chart.sh -height $term_lines -width $term_cols -timefmt HH:MM:SS
	echo "$graph_data" | bash "${CLI_DIR}/includes/chart.sh" \
		-height $term_lines \
		-width $term_cols \
		-timefmt MM:SS \
    -line-color yellow \
    -label-color cyan \
    -time-color magenta \
    -axis-color light-gray
		# -min $chart_min
}

status.chambertemp(){
	require_moonraker_api

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
			curl --silent "${MOONRAKER_API_BASE}/server/temperature_store" | \
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

	#echo "${graph_data}" | jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	#echo "$graph_data" | bash ${CLI_DIR}/includes/chart.sh -height $term_lines -width $term_cols -timefmt HH:MM:SS
	echo "$graph_data" | bash "${CLI_DIR}/includes/chart.sh" \
		-height $term_lines \
		-width $term_cols \
		-timefmt MM:SS \
    -line-color yellow \
    -label-color cyan \
    -time-color magenta \
    -axis-color light-gray
		# -min $chart_min
}

status.chamberfan(){
	require_moonraker_api

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
			curl --silent "${MOONRAKER_API_BASE}/server/temperature_store" | \
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

	#echo "${graph_data}" | jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line

	echo "${graph_data}" | bash "${CLI_DIR}/includes/chart.sh" \
		-height $term_lines \
		-width $term_cols\
		-timefmt MM:SS \
    -line-color yellow \
    -label-color cyan \
    -time-color magenta \
    -axis-color light-gray
		# -min $chart_min

}

status.chamberfanspeed(){
	require_moonraker_api

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
		curl --silent "${MOONRAKER_API_BASE}/server/temperature_store" | \
			jq --monochrome-output \
				--from-file ${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq \
				--arg limit ${graph_limit:-75} \
		 		--arg component 'temperature_fan chamber_fan' \
		 		--arg datapoint speeds |
		 		jp -height $term_lines -width $term_cols -xy "..[time,value]" -type line
	fi
}

status.temps(){
	require_moonraker_api

	local term_cols=$((`tput cols`-5))
	# Header (3 rows) + table (8 rows incl. blank) leaves the rest for the chart
	local term_lines=$((`tput lines`-12))
	[[ ${term_lines} -lt 10 ]] && term_lines=10

	local data_file="${TMP_DIR}/temperature_store.json"
	curl --silent "${MOONRAKER_API_BASE}/server/temperature_store" | jq > "${data_file}"

	# api_key | display | rgb_color | rgb_dim | power_field
	# power_field: "powers" (heaters), "speeds" (fans), or "" (pure sensors)
	local sensors=(
		"extruder|Extruder|38;2;255;82;82|38;2;128;41;41|powers"
		"heater_bed|Heater Bed|38;2;32;176;255|38;2;16;88;128|powers"
		"temperature_fan chamber_fan|Chamber Fan|38;2;60;194;90|38;2;30;97;45|speeds"
		"temperature_sensor chamber_temp|Chamber Temp|38;2;131;14;227|38;2;65;7;113|"
		"temperature_sensor mcu_temp|MCU Temp|38;2;214;118;0|38;2;107;59;0|"
	)

	# Header row + divider
	printf "  %b%-14s  %6s  %11s  %9s  %7s%b\n" "\e[1;4m" "Name" "Power" "Change" "Actual" "Target" "\e[0m"

	local tmpdir
	tmpdir=$(mktemp -d)
	local chart_args=(
		-height "$term_lines" -width "$term_cols" -timefmt MM:SS -no-legend
		-label-color cyan -time-color magenta -axis-color light-gray
	)

	local sensor_def api_key display color dim_color power_field
	local stats cur prev pwr tgt
	local change_str actual_str target_str power_str
	# Stash per-sensor chart-series specs in declaration order; appended to
	# chart_args in reverse after the loop so earlier table rows draw on top.
	local -a tgt_specs=() temp_specs=()
	for sensor_def in "${sensors[@]}"; do
		IFS='|' read -r api_key display color dim_color power_field <<< "$sensor_def"

		stats=$(jq -r --arg c "$api_key" --arg pf "$power_field" '
			.result[$c] as $r
			| (($r.temperatures // [])[-1]) as $cur
			| (($r.temperatures // [])[-2]) as $prev
			| (if $pf != "" then (($r[$pf] // [])[-1]) else null end) as $pwr
			| (($r.targets // [])[-1]) as $tgt
			| "\($cur // "")|\($prev // "")|\($pwr // "")|\($tgt // "")"
		' "$data_file")
		IFS='|' read -r cur prev pwr tgt <<< "$stats"

		[[ -n "$cur" ]] && actual_str=$(printf "%.1f °C" "$cur") || actual_str=""
		if [[ -n "$cur" && -n "$prev" ]]; then
			change_str=$(awk -v a="$cur" -v b="$prev" 'BEGIN{printf "%+.1f °C/s", a - b}')
		else
			change_str=""
		fi
		[[ -n "$tgt" ]] && target_str=$(printf "%.0f °C" "$tgt") || target_str=""
		[[ -n "$pwr" ]] && power_str=$(awk -v p="$pwr" 'BEGIN{printf "%.0f%%", p * 100}') || power_str=""

		printf "  \e[%sm%-14s\e[0m  %6s  %11s  %9s  %7s\n" \
			"$color" "$display" "$power_str" "$change_str" "$actual_str" "$target_str"

		# Skip series files for sensors with no data
		[[ -z "$cur" ]] && tgt_specs+=("") && temp_specs+=("") && continue

		local key_safe="${api_key// /_}"

		if [[ -n "$tgt" ]]; then
			local target_file="${tmpdir}/${key_safe}_target.json"
			jq --monochrome-output \
				--from-file "${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq" \
				--arg limit "${graph_limit:-500}" \
				--arg component "$api_key" \
				--arg datapoint targets \
				"$data_file" > "$target_file"
			tgt_specs+=("${display} tgt,${dim_color},${target_file}")
		else
			tgt_specs+=("")
		fi

		local temp_file="${tmpdir}/${key_safe}_temp.json"
		jq --monochrome-output \
			--from-file "${__moonraker_base_dir}/jq/filters/server.temperature_store__component__datapoint.jq" \
			--arg limit "${graph_limit:-500}" \
			--arg component "$api_key" \
			--arg datapoint temperatures \
			"$data_file" > "$temp_file"
		temp_specs+=("${display},${color},${temp_file}")
	done

	# Append series in reverse so the first table row paints last (on top).
	# Per-sensor: target before temp so the bright line stays above its dim target.
	local i
	for ((i=${#temp_specs[@]}-1; i>=0; i--)); do
		[[ -n "${tgt_specs[i]}" ]]  && chart_args+=(-s "${tgt_specs[i]}")
		[[ -n "${temp_specs[i]}" ]] && chart_args+=(-s "${temp_specs[i]}")
	done

	echo
	bash "${CLI_DIR}/includes/multiline-chart.sh" "${chart_args[@]}"

	rm -rf "$tmpdir"
}

status.wakeup(){
	printf "\e[?25lConnecting to ${MOONRAKER_HOST}:${MOONRAKER_PORT}"
	i=0
	until nc -z "${MOONRAKER_HOST}" "${MOONRAKER_PORT}" 2> /dev/null; do
		if [[ $i -eq 3 ]]; then
			#echo -e "Some text to erase: 123   \033[3D\033[KNew text\n"
			printf "\e[3D\033[K"
			i=0
		else
			printf "."
			let i++
		fi
		#printf "\rConnecting...";

		sleep 1;
	done && echo -e " Connected!\e[?25h" && show_alert "Connected to ${MOONRAKER_HOST}:${MOONRAKER_PORT}"
}

status.show(){
	require_moonraker_api

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