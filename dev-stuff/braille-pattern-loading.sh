#!/usr/bin/env bash

cd /Users/justin.hyland/Documents/scripts/bash/moonraker-cli/dev-stuff

declare -a patterns_small=('⠟' '⠯' '⠷' '⠾' '⠽' '⠻')
declare -a patterns_large=('⡿' '⣟' '⣯' '⣷' '⣾' '⣽' '⣻' '⢿')
# ➜ ✓
declare -a colors=(
    "255;249;180" "255;246;179" "255;243;177" "255;240;176" "255;237;174" "255;234;172" "255;231;171" 
    "255;228;169" "255;225;168" "255;222;166" "255;219;164" "255;216;163" "255;213;161" "255;210;160" 
    "255;207;158" "255;204;156" "255;201;155" "255;198;153" "255;195;152" "255;192;150" "255;189;148" 
    "255;186;147" "255;183;145" "255;180;144" "255;177;142" "255;174;140" "255;171;139" "255;168;137" 
    "255;165;136" "255;162;134" "255;159;132" "255;156;131" "255;153;129" "255;150;128" "255;147;126" 
    "255;144;124" "255;141;123" "255;138;121" "255;135;120" "255;132;118" "255;129;116" "255;129;116" 
    "255;127;113" "255;124;110" "255;121;107" "255;119;104" "255;116;101" "255;113;98"  "255;110;95"
    "255;108;92"  "255;105;89"  "254;102;86"  "254;99;83"   "254;97;80"   "254;94;77"   "254;91;74"  
    # "254;89;71"   "254;86;68"   "254;83;65"   "254;80;62"   "253;78;59"   "253;75;56"   "253;72;53"  
    # "253;69;50"   "253;67;47"   "253;64;44"   "253;61;41"   "253;58;38"   "253;56;35"   "252;53;32"  
    # "252;50;29"   "252;48;26"   "252;45;23"   "252;42;20"   "252;39;17"   "252;37;14"   "252;34;11"  
)

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

trap cleanup EXIT

tput civis

idx=0
color_idx=0
total_iterations=0
start_ts=$(date +%s)
elipses=0
while : ; do
    current_ts=$(date +%s)
    delta_ts=$((${current_ts}-${start_ts}))
    duration=$(gdate -d@${delta_ts} -u +%H:%M:%S)

    [[ $(($total_iterations % 5)) -eq 0 ]] && let elipses++
    [[ $(($total_iterations % 5)) -eq 0 ]] && [[ $elipses -gt 3 ]] && elipses=1
    

    echo -en "\r\e[38;2;${colors[$color_idx]};1m${patterns_large[$idx]}\e[0m [${color_idx}] \e[2m${duration}\e[0m Loading"$(repeat $elipses '.')"    "
    let idx++
    let total_iterations++

    
    # Every 5th iteration, increment the color_idx
    [[ $(($total_iterations % 5)) -eq 0 ]] && [[ $color_idx -lt $((${#colors[@]}-1)) ]] && let color_idx++

    [[ $idx -eq ${#patterns_large[@]} ]] && idx=0
    sleep 0.10
    #[[ current_time <= $cutoff ]] || break
done

exit
for char in ${patterns_small[@]}; do
    echo -en "\r${char}"
    sleep 0.5
done

echo
echo

for char in ${patterns_large[@]}; do
    echo -en "\r${char}"
    sleep 0.5
done

echo
echo