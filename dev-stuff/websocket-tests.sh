#!/usr/bin/env bash


# IP or hostname for the device running moonraker
export MOONRAKER_HOST="192.168.0.96"

# Port that the host is running moonraker on (usually 7125)
export MOONRAKER_PORT=7125

# Websocket path (without starting /)
export MOONRAKER_WSPATH='websocket' 

# https://stackoverflow.com/questions/74832052/build-nested-json-data-from-variable-with-looping-with-jq-using-bash
# https://github.com/jqlang/jq/issues/1382

function websocket_query {
    local _method="${1}"
    local _id=$RANDOM

    printf '{"jsonrpc": "2.0","method": "%s","id": %i}\n' "$_method" $_id | websocat ws://${MOONRAKER_HOST}:${MOONRAKER_PORT:=7125}/${MOONRAKER_WSPATH:=websocket} | jq 
	# printf '{"jsonrpc": "2.0","method": "%s","id": %i}\n' server.info $RANDOM | websocat ws://192.168.0.96:7125/websocket
}

function ws_payload {
	local _method=${1:-'server.info'}
	shift 
	local jq_cmd="jq --null-input "

	# --monochrome-output --raw-output --compact-output
	jq_cmd+="--compact-output "

	jq_cmd+="--arg method ${_method} "
	jq_cmd+="--arg id ${RANDOM} "

	for arg in $@; do
		read argname argval <<< $(echo "${arg}" | tr '=' '\t' )
		jq_cmd+="--arg ${argname} \"${argval}\" "
	done

	#jq_cmd+="'.jsonrpc=\"2.0\" | .id=(\$ARGS.named.id|tonumber) | .method=\$ARGS.named.method | .params=\$ARGS.named | del(.params.id) | del(.params.method)' "
	#jq_cmd+="'.jsonrpc=\"2.0\" | .id=(\$ARGS.named.id|tonumber) | .method=\$ARGS.named.method "
	#jq_cmd+="| .params=\$ARGS.named "
	#jq_cmd+="| del(.params.id) | del(.params.method)' "
    jq_cmd+="--from-file ./jq/modifiers/args2json.jq "



	echo -e "JQ COMMAND: \n\t${jq_cmd}\n" 1>&2

    echo
	echo "JQ OUTPUT:" 1>&2
	eval "${jq_cmd}" | jq 1>&2
	echo 1>&2

    echo
	echo "WEBSOCKET RESPONSE:" 1>&2
	eval "${jq_cmd}" | websocat ws://${MOONRAKER_HOST}:${MOONRAKER_PORT:=7125}/${MOONRAKER_WSPATH:=websocket} | jq 

	# read exitcode http_code http_connect response_code size_download size_header time_appconnect time_connect time_total errormsg <<< $(

	#jq --null-input \
	#	--arg bucketname "$BUCKET_NAME" \
	#	--arg objectname "$OBJECT_NAME" \
	#	--arg targetlocation "$TARGET_LOCATION" \
	#	'$ARGS.named'
}

#ws_payload server.info foo=bar baz=bang

#ws_payload server.gcode_store count=5 

# | websocat ws://${MOONRAKER_HOST}:${MOONRAKER_PORT:=7125}/${MOONRAKER_WSPATH:=websocket} | jq 

# GET /server/gcode_store?count=100
#ws_payload server.gcode_store count=5 

printf "\n\n\n"

# Expected result:
# {
#     "jsonrpc": "2.0",
#     "method": "server.gcode_store",
#     "params": {
#         "count": 100
#     },
#     "id": 7643
# }

# GET /printer/objects/query?gcode_move&toolhead&extruder=target,temperature
#ws_payload printer.objects.query objects.gcode_move objects.toolhead=position,status

# Expected result:
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




#http://192.168.0.96:7125/websocket

#ws://192.168.0.96:7125/websocket

#http://192.168.0.96:7125/printer/info


# echo '{"jsonrpc": "2.0","method": "server.info","id": 9546}' | nc 

# echo GET / HTTP/1.0 | nc 0 80

# echo '{"jsonrpc": "2.0","method": "server.info","id": 9546}' | websocat ws://192.168.0.96:7125/websocket

function websocket_args {
  local method id=$RANDOM
  declare -A params

    while [[ ${1} ]]; do
        case "${1}" in
            --method)
                method=${2}
                shift
                ;;
            --id)
                id=${2}
                shift
                ;;
			--param)
                IFS== read -r k v <<< ${2}
				params[$k]=${v}
                shift
                ;;
            *)
                echo "Unknown parameter: ${1}" >&2
                return 1
        esac

        if ! shift; then
            echo 'Missing parameter argument.' >&2
            return 1
        fi
    done

	echo "ID: $id"
	echo "method: $method"
	echo "params: ${#params[*]}"

	for k in ${!params[*]}; do
		echo -e "\t${k} = ${params[$k]}"
	done
}

#websocket_args --id 1 --method foobar --param foo=bar --param baz=bang


# {
#     "jsonrpc": "2.0",
#     "method": "server.temperature_store",
#     "params": {
#         "include_monitors": false
#     },
#     "id": 2313
# }

# jq --null-input --compact-output --raw-output \
# 	--arg method "server.gcode_store" \
# 	--arg id $RANDOM \
# 	--arg count 2 \
# 	--from-file ./jq/modifiers/args2json.jq |
# 	websocat ws://192.168.0.96:7125/websocket | 
# 	jq 

function websocket_query {
    local _method="${1}"
    local _id=$RANDOM

	jq --null-input --compact-output --raw-output \
		--arg method ${1} \
		--arg id ${RANDOM}${RANDOM} \
		--arg objects.bed_mesh profile_name \
		--from-file ./jq/modifiers/args2json.jq | tee ./tmp/${1}.json |
		websocat ws://192.168.0.96:7125/websocket | 
		jq --monochrome-output '.result' | yq --prettyPrint

		cat ./tmp/${1}.json | jq

	return
	jq --null-input --compact-output --raw-output \
		--arg method ${1} \
		--arg id ${2:-$RANDOM} \
		--arg count $(($RANDOM/10)) \
		--arg params.objects.bed_mesh null \
		--arg mamals pig,cat,dog \
		--arg seacreatures 'shark,crab,654,squid' \
		--arg name john \
		--arg enabled false \
		--arg shouldbenull null \
		--arg shouldalsobenull NULL \
		--arg foo.bar.baz "Should be at foo.bar.baz" \
		--from-file ./jq/modifiers/args2json.jq | tee /dev/stderr |
		websocat ws://192.168.0.96:7125/websocket | 
		jq --monochrome-output '.result' | yq --prettyPrint

    #printf '{"jsonrpc": "2.0","method": "%s","id": %i}\n' "$_method" $_id | websocat ws://192.168.0.96:7125/websocket | jq 
}

# jq --null-input --compact-output --raw-output \
# 	--arg method printer.objects.query \
# 	--arg id ${RANDOM} \
# 	--arg objects.bed_mesh null \
# 	--from-file ./jq/modifiers/args2json.jq | tee /dev/stderr |
# 		websocat ws://192.168.0.96:7125/websocket | 
# 		jq --monochrome-output  | yq --prettyPrint
#websocket_query printer.objects.list
websocket_query printer.objects.list


jq --null-input --compact-output --raw-output \
	--arg method printer.objects.list \
	--arg id ${RANDOM}${RANDOM} \
	--arg objects.bed_mesh profile_name \
	--from-file ./jq/modifiers/args2json.jq \
	| tee request.json \
	| websocat ws://192.168.0.96:7125/websocket \
	| jq 

jq --null-input --compact-output --raw-output \
	--arg method printer.objects.query \
	--arg id ${RANDOM}${RANDOM} \
	--arg objects.bed_mesh profile_name,profiles \
	--from-file ./jq/modifiers/args2json.jq \
	| tee request.json \
	| websocat ws://192.168.0.96:7125/websocket \
	| jq 

jq --null-input --compact-output --raw-output \
	--arg method printer.objects.query \
	--arg id ${RANDOM}${RANDOM} \
	--arg objects.bed_mesh profile_name,profiles \
	--from-file ./jq/modifiers/args2json.jq \
	| tee request.json \
	| websocat ws://192.168.0.96:7125/websocket \
	| jq 


websocat --one-message --max-messages 3 -Et tcp-l:127.0.0.1:1234 reuse-raw:ws://192.168.0.96:7125/websocket

websocat -Et tcp-l:127.0.0.1:1234 reuse-raw:ws://192.168.0.96:7125/websocket

r=${RANDOM}; jq --null-input --compact-output --raw-output \
	--arg method printer.objects.query \
	--arg id ${r} \
	--arg objects.bed_mesh profile_name,profiles \
	--from-file ./jq/modifiers/args2json.jq \
	| tee request.${r}.json \
	| nc --wait 1 -vv 127.0.0.1 1234 \
	| jq

# cat tmp/printer.objects.query.json | websocat ws://192.168.0.96:7125/websocket | jq .result | yq --prettyPrint

#printf '{"jsonrpc": "2.0","method": "server.info","id": 123}\n' | websocat ws://192.168.0.96:7125/websocket | jq 