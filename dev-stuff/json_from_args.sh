#!/usr/bin/env bash

jq --null-input \
    --arg method printer.objects.query \
    --arg id 692 \
    --arg objects.gcode_move null \
    --arg objects.toolhead position,status \
    --from-file ./jq/modifiers/args2json.jq

