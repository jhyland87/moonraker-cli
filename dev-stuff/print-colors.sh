#!/usr/bin/env bash

for n in `seq 18 21` `seq 24 27` `seq 30 33` 38 39 44 45 50 51 159 74 75 80 81 86 87 117 123; do 
	# Set the bg color, then invert the colors so the text is more readable on the bg
	# 	"\e[38;5;${n};3;7m"
	# Just set the bg color:
	# 	"\e[48;5;${n};3m"
	printf "%-3i %-15s %b%s\e[0m\n" "$n" "\e[48;5;${n};3m" "\e[38;5;${n};3;7m" "Hello World"
done; echo

