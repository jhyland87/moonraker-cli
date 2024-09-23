#!/usr/bin/env bash

source ${CLI_DIR}/includes/common.sh


function websocket_query {
    local _method="${1}"
    local _id=$RANDOM

    printf '{"jsonrpc": "2.0","method": "%s","id": %i}\n' "$_method" $_id | websocat ws://${MOONRAKER_HOST}:${MOONRAKER_PORT:=7125}/${MOONRAKER_WSPATH:=websocket} | jq 
}