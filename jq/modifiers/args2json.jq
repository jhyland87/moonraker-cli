# DESCRIPTION:
#   Formats the arguments provided to jq into a websocket friendly payload.
#
# USAGE:
#
# EXAMPLES:
#   jq --null-input \
#       --arg method server.gcode_store \
#       --arg id $RANDOM \
#       --arg count $(($RANDOM /10)) \
#       --arg mamals pig,cat,dog \
#       --arg seacreatures 'shark,crab,654,squid' \
#       --arg name john \
#       --arg enabled false \
#       --arg shouldbenull null \
#       --arg shouldalsobenull NULL \
#       --arg foo.bar.baz "Should be at foo.bar.baz" \
#       --from-file ./jq/modifiers/args2json.jq
#
#   Returns:
#     {
#       "jsonrpc": "2.0",
#       "id": 22623,
#       "method": "server.gcode_store",
#       "params": {
#         "count": 56,
#         "mamals": [
#           "pig",
#           "cat",
#           "dog"
#         ],
#         "seacreatures": [
#           "shark",
#           "crab",
#           654,
#           "squid"
#         ],
#         "name": "john",
#         "enabled": false,
#         "shouldbenull": null,
#         "shouldalsobenull": null,
#         "foo": {
#           "bar": {
#             "baz": "Should be at foo.bar.baz"
#           }
#         }
#       }
#     }
#
#
#   jq --null-input --compact-output --raw-output \
#   	--arg method "server.temperature_store" \
#   	--arg id $RANDOM \
#   	--arg include_monitors false \
#   	--from-file ./jq/modifiers/args2json.jq |
#   	websocat ws://192.168.0.96:7125/websocket | 
#   	jq
#
#   jq --null-input --compact-output --raw-output \
#   	--arg method "server.gcode_store" \
#   	--arg id $RANDOM \
#   	--arg count 2 \
#   	--from-file ./jq/modifiers/args2json.jq |
#   	websocat ws://192.168.0.96:7125/websocket | 
#   	jq 
# 

# Cast some text into the most likely value and appropriate data type
def cast_arg:
    . as $val |
    if ($val|ascii_downcase) == "null" 
        then null
    elif ($val|ascii_downcase) == "true" 
        then true
    elif ($val|ascii_downcase) == "false" 
        then false
    else ( $val |
        try tonumber catch ($val 
            | split(",") as $segments |
            if ($segments|length) == 0 
                then null
            elif ($segments|length) == 1 
                then $val 
            else 
                ($segments|map(cast_arg))
            end
        )
    ) end;
    

# Take the --arg foo.bar baz,bang,qux into {foo: {bar: [baz, bang, qux]}}
def args2json:
    . as $params |
    reduce to_entries[] as $e (null;
        #debug($e) |
        setpath($e.key | split("."); $e.value | cast_arg)
    );

.jsonrpc="2.0" |
    .id=($ARGS.named.id|tonumber) | 
    .method=$ARGS.named.method  |
    .params=($ARGS.named | args2json) |
    del(.params.method ) |
    del(.params.id )