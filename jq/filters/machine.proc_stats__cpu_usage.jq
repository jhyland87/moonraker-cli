# Create line-graphable data array from the moonraker_stats array
# returned from /machine/proc_stats.
#	
# Example output:
# 	[
# 	  { "time": 1724318638, "cpu_usage": 7.08 },
# 	  { "time": 1724318639, "cpu_usage": 2.33 },
# 	  { "time": 1724318640, "cpu_usage": 4.9 }
# 	]
#
# Example usage:
# 	curl --silent http://192.168.0.96:7125/machine/proc_stats | 
# 		jq --from-file jq/filters/machine.proc_stats__moonraker_stats.jq | 
# 		jp  -xy "..[time,cpu_usage]" -type line

[.result.moonraker_stats[] | {
	time: (.time|tostring | .[5:10] | tonumber), 
	cpu_usage: .cpu_usage
}]


