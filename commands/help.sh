#!/usr/bin/env bash


listcommands(){
	local cmdlist=$(ls -1 commands | sed -E -e 's/\.sh$//g')


	#export -f _help _description
}



echo "Hello from help"
