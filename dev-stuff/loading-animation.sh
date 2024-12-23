

#chars="⡀⡄⡆⡇⡏⡟⡿⢿⢻⢹⢸⢰⢠⢀"
#chars="⡇⠏⠛⠹⢸⣰⣤⣆"
chars="⡏⠟⠻⢹⣸⣴⣦⣇"


start_ts=$(gdate +%s)
grep -o . <<< "${chars}${chars}${chars}${chars}${chars}${chars}${chars}" | while read char; do
    current_ts=$(gdate +%s)
    delta_sec=$(($current_ts-$start_ts))
    delta_ts=$(gdate -d@$delta_sec -u +%H:%M:%S)
    #echo -en "\r\e[33;1m${char}\e[0m Loading..."
    printf "\r\e[33;1m%s\e[0m %10s %10s" "$char" "${delta_ts}" "Loading..."
    sleep 0.25
done
echo
