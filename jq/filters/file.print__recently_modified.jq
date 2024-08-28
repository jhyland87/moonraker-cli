# 
# ----
# curl -s 'http://192.168.0.96:7125/server/files/list?root=gcodes' | 
# 	jq --monochrome-output --raw-output \
# 		-L './jq/' \
# 		--from-file ./jq/filters/file.print__recently_modified.jq \
# 		--arg limit 10
#
#   Output:
#    [
#      {
#        "name": "ex_tailgate_3_v1__ASA_lh0.20mm_d15%_n0.4__K1C_20240822-144246.gcode",
#        "directory": "rc-cybertruck",
#        "path": "rc-cybertruck/ex_tailgate_3_v1__ASA_lh0.20mm_d15%_n0.4__K1C_20240822-144246.gcode",
#        "size": 9439635,
#        "size_human": "9.44 MB",
#        "modified": 1724362976.4302409,
#        "date": "2024-08-22T21:42:56Z"
#      },
#      ... Up to 9 other records
#    }
# ----
# curl --silent 'http://192.168.0.96:7125/server/files/list?root=gcodes' | 
# 	jq  --monochrome-output --raw-output \
# 		-L './jq/'  \
# 		--from-file ./jq/filters/file.print__recently_modified.jq \
# 		--arg limit 3
#
#   Output:
#    [
#      {
#        "name": "ex_tailgate_3_v1__ASA_lh0.20mm_d15%_n0.4__K1C_20240822-144246.gcode",
#        "directory": "rc-cybertruck",
#        "path": "rc-cybertruck/ex_tailgate_3_v1__ASA_lh0.20mm_d15%_n0.4__K1C_20240822-144246.gcode",
#        "size": 9439635,
#        "size_human": "9.44 MB",
#        "modified": 1724362976.4302409,
#        "date": "2024-08-22T21:42:56Z"
#      },
#      ... Up to 3 other records
#    ]
# ----
# Sort by file path
#   curl --silent 'http://192.168.0.96:7125/server/files/list?root=gcodes' | 
#   	jq  --monochrome-output --raw-output \
#   		-L './jq/'  \
#   		--from-file ./jq/filters/file.print__recently_modified.jq \
#   		--arg limit 3 \
#   		--arg sort_by path
#
#   Output:
#    [
#      {
#        "name": "v2_block_jonction_ss-sh_x1__PETG_lh0.20mm_d10%_n0.4__K1C_20240623-014503.gcode",
#        "directory": "starship",
#        "path": "starship/v2_block_jonction_ss-sh_x1__PETG_lh0.20mm_d10%_n0.4__K1C_20240623-014503.gcode",
#        "size": 1495263,
#        "size_human": "1.5 MB",
#        "modified": 1719132318.8176918,
#        "date": "2024-06-23T08:45:18Z"
#      },
#      {
#        ...
#      },
#      {
#        ...
#      }
#    ]
# ----
# Show only the most recently modified file
#   curl --silent 'http://192.168.0.96:7125/server/files/list?root=gcodes' | 
#   	jq  --monochrome-output --raw-output \
#   		-L './jq/' \
#   		--from-file ./jq/filters/file.print__recently_modified.jq \
#   		--arg limit 1 \
#   		--arg sort_by modified |
#	  		jq --raw-output '.[].name'
#
#   Output: ex_tailgate_3_v1__ASA_lh0.20mm_d15%_n0.4__K1C_20240822-144246.gcode
# 
#
#    [
#      {
#        "name": "ex_tailgate_3_v1__ASA_lh0.20mm_d15%_n0.4__K1C_20240822-144246.gcode",
#        "directory": "rc-cybertruck",
#        "path": "rc-cybertruck/ex_tailgate_3_v1__ASA_lh0.20mm_d15%_n0.4__K1C_20240822-144246.gcode",
#        "size": 9439635,
#        "size_human": "9.44 MB",
#        "modified": 1724362976.4302409,
#        "date": "2024-08-22T21:42:56Z"
#      }
#    ]


include "utils"; 
(if ($ARGS.named | has("limit")) then ($ARGS.named["limit"] | tonumber)  else 10 end) as $display_limit |
(if ($ARGS.named | has("sort_by")) then $ARGS.named["sort_by"] else "modified" end) as $sort_by |
[.result[] | {
	name: (.path | split("/")[-1]),
	#directory: "/"(.path | split("/")[0:-1] | join("/")),
	path: .path, 
	size: .size, 
	size_human: (.size|bytes),
	modified: .modified,
	date: (.modified|todate)
}] 
| sort_by(getpath([$sort_by])) 
| reverse 
|.[0:$display_limit] #| .[].path