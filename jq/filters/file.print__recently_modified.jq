# curl -s 'http://192.168.0.96:7125/server/files/list?root=gcodes' | 
# 	jq --monochrome-output --raw-output \
# 		-L './jq/' \
# 		--from-file ./jq/filters/file.print__recently_modified.jq \
# 		--arg limit 10
#
# curl --silent 'http://192.168.0.96:7125/server/files/list?root=gcodes' | 
# 	jq  --monochrome-output --raw-output \
# 		-L './jq/'  \
# 		--from-file ./jq/filters/file.print__recently_modified.jq \
# 		--arg limit 3
#
# Sort by file path
# curl --silent 'http://192.168.0.96:7125/server/files/list?root=gcodes' | 
# 	jq  --monochrome-output --raw-output \
# 		-L './jq/'  \
# 		--from-file ./jq/filters/file.print__recently_modified.jq \
# 		--arg limit 3 \
# 		--arg sort_by path
#
# Show only the most recently modified file
# curl --silent 'http://192.168.0.96:7125/server/files/list?root=gcodes' | 
# 	jq  --monochrome-output --raw-output \
# 		-L './jq/' \
# 		--from-file ./jq/filters/file.print__recently_modified.jq \
# 		--arg limit 1 \
# 		--arg sort_by modified |
#			jq --raw-output '.[].name'


include "utils"; 
(if ($ARGS.named | has("limit")) then ($ARGS.named["limit"] | tonumber)  else 10 end) as $display_limit |
(if ($ARGS.named | has("sort_by")) then $ARGS.named["sort_by"] else "modified" end) as $sort_by |
[.result[] | {
	name: (.path | split("/")[-1]),
	directory: (.path | split("/")[0:-1] | join("/")),
	path: .path, 
	size: .size, 
	size_human: (.size|bytes),
	modified: .modified,
	date: (.modified|todate),
	sort_by: $sort_by,
	display_limit: $display_limit
}] | sort_by(getpath([$sort_by])) | reverse |.[0:$display_limit] #| .[].path