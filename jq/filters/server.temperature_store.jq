# Retrieve the server.temperature_store data, but limit the amount of data points returned by setting the 
# 	$limit value using --arg
# Example:
# 	curl --silent 'http://192.168.0.96:7125/server/temperature_store' | \
# 		jq --arg limit 10 --from-file ./jq-filters/server.temperature_store.jq

(-($limit | tonumber)) as $start_idx 
| .result |= {
		heater_bed: .heater_bed, 
		extruder: .extruder
	} 
| .result 
| to_entries 
| map(. | {
			key: .key, 
			value: {
				temperatures: .value.temperatures[$start_idx:], 
				targets: .value.targets[$start_idx:], 
				powers: .value.powers[$start_idx:]
			}
		} 
	) 
| from_entries

