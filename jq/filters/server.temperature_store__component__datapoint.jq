
# Format a specific temperature datapoint (argument) into a structure that can be used by jp -xy
#
# Arguments:
# 	limit: How many temp values to return (ie: how many seconds back from now)
# 	component: Can be extruder, temperatures, mcu_temp, chamber_temp or chamber_fan
# 	datapoint: Can be speeds, temperatures, targets or powers (Must be a key under compoents object)
#
# Example Output:
# 	[ 
# 		{ "index": 0, "time": 27, "value": 55.41 },
# 		{ "index": 1, "time": 28, "value": 55.28 },
# 		{ "index": 2, "time": 29, "value": 55.18 },
# 		{ "index": 3, "time": 30, "value": 55.07 },
# 		{ "index": 4, "time": 31, "value": 54.96 },
# 		{ "index": 5, "time": 32, "value": 54.86 },
# 		{ "index": 6, "time": 33, "value": 54.75 },
# 		{ "index": 7, "time": 34, "value": 54.63 },
# 		{ "index": 8, "time": 35, "value": 54.55 },
# 		{ "index": 9, "time": 36, "value": 54.45 }
# 	]
#
# Example:
# 	curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
# 		jq --monochrome-output \
# 			--from-file ./jq-filters/server.temperature_store__component__datapoint.jq \
# 			--arg limit 10 \
# 	 		--arg component extruder \
# 	 		--arg datapoint temperatures  | jp -xy "..[time,value]" -type line
#
($limit | tonumber) as $limit 
| (-($limit)) as $start_idx 
| .result[$component][$datapoint][$start_idx:] 
| to_entries 
| map(. | {
	index:.key, 
	time: ((now-($limit-1-.key)) | tonumber), # Outputs the time in HHMMSS format
	value: .value 
})

