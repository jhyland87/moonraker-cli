#!/usr/bin/env jq --slurp --raw-output --from-file 

include "./jq/utils";

    #   const cputime = stats.cputime
    #   const last_cputime = state.printer.printer.system_stats?.cputime || stats.cputime || 0

    #   update_time = eventtime
    #     proc_time = time.process_time()
    #     time_diff = update_time - self.last_update_time
    #     usage = round((proc_time - self.last_proc_time) / time_diff * 100, 2)


.[0] * .[1] * .[2]
    | .result 
    | .mcu.mcu_stats.last_stats = .moonraker_stats[-2]
    | .mcu.mcu_stats.current_stats = .moonraker_stats[-1]
    | .cpu_time_change = (.eventtime-.status.system_stats.cputime * 100)
    
    | .system_stats = .status.system_stats
    | [.system_info.cpu_info, .status.system_stats, .system_cpu_usage, .mcu] 
    | .[0] * .[1] * .[2] * .[3]  
    | .memused = (.total_memory-.memavail) 
    | .cputime_diff = ((.mcu_stats.current_stats.time - .mcu_stats.last_stats.time) * 100)
    | .percents.system_memory = (.memused / .total_memory * 100 | ceil)
    | .percents.klipper_load = .cpu 
    | .percents.moonraker_cpu = .cpu_usage
    | .percents.sysload = (.sysload/.cpu_count * 100)
    #   const total_memory = state.server.system_info?.cpu_info?.total_memory || 0
    #   const mem_used = total_memory - stats.memavail
    #   const percent_mem_used = Math.ceil(mem_used / total_memory * 100)
    | [{
        #"MEM": ((100/.total_memory)*.memused | floor),
        "mem": ((.memused/.total_memory)*100 | floor),
        "load": ((.sysload/.cpu_count)*100 | floor),
        "cpu": .cpu
      }]
    | objectArray2CSV
#    #


# .[0] * .[1] * .[2] 
#     | .result 
#     | [.system_info.cpu_info, .status.system_stats, .system_cpu_usage] 
#     | .[0] * .[1] * .[2] 
#     | .memused = (.total_memory-.memavail) 
#     | [
#         ((100/.total_memory)*.memused | floor),
#         ((.sysload/.cpu_count)*100 | floor),
#         .cpu, 
#         .cpu0, 
#         .cpu1
#       ]
#     | @tsv;