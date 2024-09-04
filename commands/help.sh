#!/usr/bin/env bash


listcommands(){
	local cmdlist=$(ls -1 commands | sed -E -e 's/\.sh$//g' | grep -Ev '^(example|help)$')

	echo "Available commands: "

	for cmd in $cmdlist; do
		printf "    %-10s - " "${cmd}"

		./commands/${cmd}.sh --description
	done 
}


echo "moonraker - commandline moonraker interface"
echo
echo "Usage:  moonraker <command> [options...]"
echo
echo "Example:"
echo 
echo "    moonraker printer status"
listcommands
