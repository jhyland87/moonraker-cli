#!/usr/bin/env bash

# http://192.168.0.96:7125/server/temperature_store?include_monitors=false


#curl http://192.168.0.96:7125 \
#	--request GET \
#	--request-target /server/temperature_store \
#	--connect-timeout 5 \
#	--silent \
#	--data "include_monitors=false" | jq --color-output --arg limit 5 --from-file ./jq-filters/server.temperature_store.jq

# 14.76
#watch --no-title --interval 1 ./temp-chart.sh

term_width=$((`tput cols`-5))
term_lines=$((`tput lines`/2-3))


echo -e "CHAMBER_FAN TEMPERATURES\n"
curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
	jq --monochrome-output \
		--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
		--arg limit 75 \
		--arg component "temperature_fan chamber_fan" \
		--arg datapoint temperatures | 
		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line

echo
echo -e "EXTRUDER TEMPERATURES\n"
curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
	jq --monochrome-output \
		--from-file ./jq/filters/server.temperature_store__component__datapoint.jq \
		--arg limit 75 \
 		--arg component extruder \
 		--arg datapoint temperatures | 
 		jp -height $term_lines -width $term_width -xy "..[time,value]" -type line

 		#|  jp -y '.temperatures[*].time'  -x '.temperatures[*].value' 


#cat mock-temp-data.json | jp  -x '.temperatures[*].time'  -y '.temperatures[*].value' 

#cat mock-temp-data.json | jp -xy "..[time,value]" -type bar

#cat mock-temp-data-arr.json | jp -xy "..[Label,Count]" -type bar

# --monochrome-output
# '.result |= {heater_bed: .heater_bed, extruder: .extruder} | .result | to_entries | map(. | { key: .key, value: {temperatures: .value.temperatures[-($limit|tonumber):], targets: .value.targets[-($limit|tonumber):], powers: .value.powers[-($limit|tonumber):]}} ) | from_entries'
#  | map(. | { key:.key, value: (with_entries(.value |= .value[0:10]))})

# 

# jq --color-output --arg limit '-10' '.result |= {heater_bed: .heater_bed, extruder: .extruder} | .result | to_entries | map(. | { key: .key, value: {temperatures: .value.temperatures[-($limit|tonumber):], targets: .value.targets[-($limit|tonumber):], powers: .value.powers[-($limit|tonumber):]}} )'

# jq --color-output --arg limit 10 '.result.extruder | .limit = ($limit|tonumber)'
# | jq --color-output '.result.extruder | .targets = .targets[0:10]'


# map_values( to_entries[-2:] | from_entries)