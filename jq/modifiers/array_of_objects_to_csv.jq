# DESCRIPTION: 
# 	Will take an array of similar basic objects like:
#   	[
#    		{ "id": 1, "first_name": "John", "last_name": "Doe"},	
#    		{ "id": 2, "first_name": "Jane", "last_name": "Smith"},	
#    	]
#    
# and return an array of arrays with 1 new record at the top containing 
# the keys (for the csv/tsv headers):
#			[
#  			["id","first_name", "last_name"],
#    		[1, "John", "Doe"],
#    		[2, "Jane", "Smith"]
#    	]
#
# USAGE:
# 
# 	curl --silent 'http://192.168.0.96:7125/server/files/list?root=gcodes' | 
#     	jq  --monochrome-output --raw-output \
#     		-L './jq/'  \
#     		--from-file ./jq/filters/file.print__recently_modified.jq \
#     		--arg limit 3 | \
# 			jq --monochrome-output --raw-output \
#					-L './jq/' \
#					--from-file ./jq/modifiers/array_of_objects_to_csv.jq
#
# OUTPUT:
#    "name","path","size","size_human","modified","date"
#    "file_one.gcode","file_one.gcode",9439635,"9.44 MB",1724362976.4302409,"2024-08-22T21:42:56Z"
#    "file_two.gcode","project_folder/file_two.gcode",1218625,"1.22 MB",1724361836.9251854,"2024-08-22T21:23:56Z"
#    "file_three.gcode","project_folder/file_three.gcode",1355597,"1.36 MB",1724323074.738102,"2024-08-22T10:37:54Z"
#
# -----
# Output a tab delimited and aligned list of files
#    curl --silent 'http://192.168.0.96:7125/server/files/list?root=gcodes' | 
#     	jq  --monochrome-output --raw-output \
#     		-L './jq/'  \
#     		--from-file ./jq/filters/file.print__recently_modified.jq \
#     		--arg limit 3 | 
#     	jq --monochrome-output --raw-output \
#					-L './jq/' \
#					--from-file ./jq/modifiers/array_of_objects_to_csv.jq \
#					--arg output tsv | 
#				column -ts $'\t'
#
# OUTPUT:
#    name              path                             size     size_human  modified            date
#    file_one.gcode    file_one.gcode                   9439635  9.44 MB     1724362976.4302409  2024-08-22T21:42:56Z
#    file_two.gcode    project_folder/file_two.gcode    1218625  1.22 MB     1724361836.9251854  2024-08-22T21:23:56Z
#    file_three.gcode  project_folder/file_three.gcode  1355597  1.36 MB     1724323074.738102   2024-08-22T10:37:54Z
#    
#    

(if type!="array" then error("root needs to be an array") end)
| (if (.[0] | type!="object") then error("first array entry is not an object") end)
| (.[0] | to_entries | map(.key)) as $column_names 
| (if length == 0 then halt end)
| (
	$column_names
),
(
	.[] 
	| select(type == "object") 
	| to_entries 
	| map(select(.key == ("name","path","size","date"))) 
	| map(.value)
	#.[] | select(type == "object") | to_entries | [ .[] | select(.key == ($column_names))]
) 
| if ($ARGS.named | has("output")) and $ARGS.named["output"] == "tsv" then @tsv else @csv end


