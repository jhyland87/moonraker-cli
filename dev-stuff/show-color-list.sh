#!/usr/bin/env bash

cd /Users/justin.hyland/Documents/scripts/bash/moonraker-cli/dev-stuff

pos_count=0
while read color; do
    echo -en "\e[48;2;${color}m"
    echo -n 'positive_colors['${pos_count}']="'${color}'";'
    echo -e "\e[0m"
    let pos_count++
    #printf "\e[48;2;%sm%s\e[0m\n" $color "    ";
done < <(tac positive-colors.list)

echo
neg_count=0
while read color; do
    echo -en "\e[48;2;${color}m"
    echo -n 'negative_colors['${neg_count}']="'${color}'";'
    echo -e "\e[0m"
    let neg_count++
    #printf "\e[48;2;%sm%s\e[0m\n" $color "    ";
done < negative-colors.list 

echo
echo "pos_count: ${pos_count}"
echo "neg_count: ${neg_count}"