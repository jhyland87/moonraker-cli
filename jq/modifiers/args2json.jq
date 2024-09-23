# DESCRIPTION:
#   Formats the arguments provided to jq into a websocket friendly payload.
#
# USAGE:
#
# EXAMPLE:
#   jq --null-input \
#       --arg method server.gcode_store \
#       --arg id 692 \
#       --arg count 5 \
#       --arg mamals pig,cat,dog \
#       --arg seacreatures 'shark,crab,654,squid' \
#       --arg name john \
#       --arg enabled false \
#       --arg shouldbenull null \
#       --from-file ./jq/modifiers/args2json.jq
#
# Returns:
#   {
#     "jsonrpc": "2.0",
#     "id": 692,
#     "method": "server.gcode_store",
#     "params": {
#       "count": 5,
#       "mamals": ["pig","cat","dog"],
#       "seacreatures": ["shark","crab",654,"squid" ],
#       "name": "john",
#       "enabled": false,
#       "shouldbenull": null
#     }
#   }


def cast_arg:
    . as $val |
    if $val == "null" then null
    elif $val == "true" then true
    elif $val == "false" then false
    else ( $val 
        | try tonumber catch ($val
            | split(",") as $segments 
            | if ($segments|length) == 0 then null
              elif ($segments|length) == 1 then $val 
              else ($segments|map(cast_arg))
              end
        )
    ) end;
    

def args2json:
#    . as $params | to_entries | reduce .[] as $entrties ({}; $entrties | (setpath(.key | split("."); .value | split(",")) | del(.key) | del(.value))) ;
    . as $params | to_entries | reduce .[] as $entrties ([]; $entrties | (setpath(.key | split("."); .value | cast_arg) | del(.key) | del(.value) | $params + . ) ) ;




.jsonrpc="2.0" 
| .id=($ARGS.named.id|tonumber) 
| .method=$ARGS.named.method  
#| del($ARGS.named.method ) 
#| del($ARGS.named.id )
| .params=($ARGS.named | args2json) 
#| del(.params.id) 
#| del(.params.method) 



# .params=($ARGS.named 
#     | map_values( cast )
#     ) | del(.params.id) | del(.params.method) 

# map(if . % 2 == 0 then ., "hi" else . + 1 end)



# .params=($ARGS.named 
#     | map_values( . as $val 
#         | if $val == "null" 
#             then null 
#             else ( $val 
#                 | try tonumber catch ($val
#                     | split(",") as $segments 
#                     | if ($segments|length) == 1 
#                         then $val 
#                         else ($segments | map(., try tonumber))
#                     end
#                 )
#             ) end
#         )
#     ) | del(.params.id) | del(.params.method) 