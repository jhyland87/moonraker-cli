#!/usr/bin/env bash

jq --null-input \
    --arg method server.gcode_store \
    --arg id $RANDOM \
    --arg count $(($RANDOM /10)) \
    --arg mamals pig,cat,dog \
    --arg seacreatures 'shark,crab,654,squid' \
    --arg name john \
    --arg enabled false \
    --arg shouldbenull null \
    --arg shouldalsobenull NULL \
    --arg foo.bar.baz "Should be at foo.bar.baz" \
    --from-file ./jq/modifiers/args2json.jq


exit
# /printer/objects/query?gcode_move&toolhead&extruder=target,temperature



curl --silent 'http://192.168.0.96:4408/printer/objects/query?gcode_move&toolhead&extruder=target,temperature' | 
    jq --null-input \
        --arg method printer.objects.query \
        --arg id 692 \
        --arg objects.gcode_move null \
        --arg objects.toolhead position,status \
        --from-file ./jq/modifiers/args2json.jq


# {
#     "jsonrpc": "2.0",
#     "method": "printer.objects.query",
#     "params": {
#         "objects": {
#             "gcode_move": null,
#             "toolhead": ["position", "status"]
#         }
#     },
#     "id": 4654
# }



(.; ($edit[0] | (if type == "array" then . else [.] end)) as $path
        | setpath( $path; $edit[1] ) );

   map(., .key=(.key|split("."))) | map(., setpath(.key, .value))