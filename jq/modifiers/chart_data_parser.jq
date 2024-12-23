#!/usr/bin/env jq --slurp --raw-output --from-file 


include "./jq/utils";

.[0] * .[1] * .[2] 
    | .result 
    | [.system_info.cpu_info, .status.system_stats, .system_cpu_usage] 
    | .[0] * .[1] * .[2] 
    | .memused = (.total_memory-.memavail) 
    | [
        ((100/.total_memory)*.memused | floor),
        ((.sysload/.cpu_count)*100 | floor),
        .cpu, 
        .cpu0, 
        .cpu1
      ]
    | @tsv