#!/usr/bin/env bash

source ./settings

function ws_payload {
	local _method=${1:-'server.info'}
	shift 
	local jq_cmd="jq --null-input "

	# --monochrome-output --raw-output --compact-output
	jq_cmd+="--compact-output " # Required
	#jq_cmd+="--monochrome-output  " # Does work without this

	jq_cmd+="--arg method ${_method} "
	jq_cmd+="--arg id ${RANDOM} "

	for arg in $@; do
		read argname argval <<< $(echo "${arg}" | tr '=' '\t' )
		jq_cmd+="--arg ${argname} \"${argval}\" "
	done

	#jq_cmd+="'.jsonrpc=\"2.0\" | .id=(\$ARGS.named.id|tonumber) | .method=\$ARGS.named.method | .params=\$ARGS.named | del(.params.id) | del(.params.method)' "
	jq_cmd+="'.jsonrpc=\"2.0\" | .id=(\$ARGS.named.id|tonumber) | .method=\$ARGS.named.method "
	jq_cmd+="| .params=(\$ARGS.named | map_values(if . | type == "string" then . | ascii_upcase else . end) ) "
	jq_cmd+="| del(.params.id) | del(.params.method)' "

jq --null-input --arg animals pig,cat,dog --arg name john '.params=\$ARGS.named '

	echo -e "JQ COMMAND: \n\t${jq_cmd}\n" 1>&2
    echo
	echo "JQ OUTPUT:" 1>&2
	eval "${jq_cmd}" | jq 1>&2
	echo 1>&2
    return
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


