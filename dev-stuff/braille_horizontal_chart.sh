#!/usr/bin/env bash


readarray -t colors < ./includes/data/loading-colors.list
declare -A chars=(
    [0_0_0_0]='⠀' [0_1_0_0]='⠂'  [0_0_1_0]='⠄' [0_0_0_1]='⡀'
                  [0_1_1_0]='⠆' [0_1_0_1]='⡂' [0_1_1_1]='⡆' 
                  [0_2_0_0]='⠒' [0_2_1_0]='⠖' [0_2_0_1]='⡒' [0_2_1_1]='⡖' 
                  [0_2_2_0]='' [0_2_2_1]=''  [0_2_2_2]=''
                  [0_0_2_0]='' [0_1_2_0]='' [0_1_2_1]=''
    [1_0_0_0]='⠁' [1_1_0_0]='' [1_0_1_0]='⠅' [1_0_0_1]='⡁'

    [2_2_2_2]='⣿'
    [1_0_0_0]='⠁' [1_1_0_0]=''
    [0_0_1_1]='⡄' [0_1_1_1]='⡆' [1_1_1_1]='⡇'
    [2_0_0_0]='⠉' [2_1_0_0]='⠋' [2_1_1_0]='⠏' [2_1_1_1]='⡏'

    [0_0_0_1]='⡀' [0_0_1_1]='⡄' [0_1_1_1]='⡆' [1_1_1_1]='⡇'
    [0_0_1_1]='⡄' 
    [0_0_0_2]='⣀' [0_0_1_2]='⣄' [0_1_1_2]='⡆' [1_1_1_2]='⡇'

    [1_1_1_0]='' []='' []='' []='' []='' []='' []='' []=''
    [1_1]='⣀' [1_2]='⣠' [1_3]='⣰' [1_4]='⣸'
   [2_1]='⣄' [2_2]='⣤' [2_3]='⣴' [2_4]='⣼'
    [3_1]='⣆' [3_2]='⣦' [3_3]='⣶' [3_4]='⣾'
     [4_1]='⣇' [4_2]='⣧' [4_3]='⣷' [4_4]='⣿'
)

# while IFS== read -r key value; do
#     #ary[$key]=$value
#     chars["$key"]="$value"
# done < "dev-stuff/brale_chart_chars.list"


repeat(){
	local start=1
	local end=${1:-80}
	local str="${2:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
}

cleanup() {
    tput cnorm
}

function _randInt {
    local limit=${1:-10}

    echo -n $((RANDOM % (${limit}+1)))
}

function _randChange {
    echo -e $(((RANDOM % 3)-1))
}


trap cleanup EXIT

tput civis

loop_sleep_interval=0.1

declare -a chart_values=(0 0 0 0)

function update_chart {

    local chart_group_count=$(((${#chart_values[@]}/2)+1))
    local line="\r"

    i=0
    while [[ $i -lt ${#chart_values[@]} ]]; do
        val_a=${chart_values[$i]}
        val_b=0
        let i++
        if [[ $i -lt ${#chart_values[@]} ]]; then
            val_b=${chart_values[$i]}
            let i++
        fi

        line="${line}\e[38;2;255;249;180m${chars[${val_a}_${val_b}]}\e[0m" 
    done

    
    echo -en "${line} - ${chart_values[@]}"
}

while : ; do
    for ((i=0;i<${#chart_values[@]};i++));do
        old_value=${chart_values[$i]}
        new_value=$((${chart_values[$i]}))
        change=$(_randChange)
        [[ $change -eq 1 ]] && [[ $new_value -lt 4 ]] && let new_value++
        [[ $change -eq -1 ]] && [[ $new_value -gt 0 ]] && let new_value--

        [[ $new_value -ne $old_value ]] && chart_values[$i]=$new_value
    done

    update_chart
    sleep $loop_sleep_interval

done

echo