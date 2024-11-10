.result |= {heater_bed: .heater_bed, extruder: .extruder} 
| .result 
| to_entries 
| map(. | { 
    key: .key, 
    value: {
        temperatures: .value.temperatures[-($limit|tonumber):], 
        targets: .value.targets[-($limit|tonumber):], 
        powers: .value.powers[-($limit|tonumber):]
    }
}) 
| from_entries