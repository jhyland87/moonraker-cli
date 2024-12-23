#!/usr/bin/env bash
#
# by Dennis Williamson - 2012-07-26
# for http://stackoverflow.com/questions/11594670/generate-color-fades-via-bash
#
# fade smoothly from any arbitrary color to another
#
# no values are range checked, but this feature could be easily added
#

set_color () {
    local light=$1
    red=$2 green=$3 blue=$4 # global - see below
    # placeholder for the command that sets led color on a particular light
    #echo "$light, $red, $green, $blue"
    #echo -e "\x1b[38;2;${red};${green};${blue}m.\e[0m"
    #printf "\e[30m%b%-11s\e[0m\n" "\e[48;2;${red};${green};${blue}m" "${red};${green};${blue}" ;
    printf "\e[30m%b%-1s\e[0m" "\e[48;2;${red};${green};${blue}m" " " ;

    #echo -e "\e[30m\e[48;2;${red};${green};${blue}m${red};${green};${blue}\e[0m"
}

abs () {
    if [ $1 -lt 0 ]
    then
        echo "$(($1 * -1))"
    else
        echo "$1"
    fi
}

max () {
    local arg max=0
    for arg
    do
        if [ "$arg" -gt "$max" ]
        then
            max=$arg
        fi
    done
    echo "$max"
}

fade () {
    local light=$1 step=$2 sleep=$3
    local start_red=$4 start_green=$5 start_blue=$6
    local end_red=$7 end_green=$8 end_blue=$9
    local delta_red=$(abs $(($end_red - $start_red)) )
    local delta_green=$(abs $(($end_green - $start_green)) )
    local delta_blue=$(abs $(($end_blue - $start_blue)) )
    local i=0
    local max=$(max "$delta_red" "$delta_green" "$delta_blue")

    if test $DEBUG; then
        echo "-------------------"
        printf "light: %s\n" "${light}"
        printf "step: %s\n" "${step}"
        printf "sleep: %s\n" "${sleep}"
        printf "start RGB: %s;%s;%s\n" $start_red $start_green $start_blue
        printf "end RGB: %s;%s;%s\n" $end_red $end_green $end_blue
        printf "delta RGB: %s;%s;%s\n" $delta_red $delta_green $delta_blue
        printf "max: %s\n" "${max}"
        echo "-------------------"

    fi

    if [ "$delta_red" = 0 ] && [ "$delta_green" = 0 ] && [ "$delta_blue" = 0 ]
    then
        return
    fi

    if [ "$step" -lt 1 ]
    then
        step=1
    fi

    while [ "$i" -le "$max" ]
    do

        red=$(( $start_red + ($end_red - $start_red)  * $i / $max ))
        green=$(( $start_green + ($end_green - $start_green) * $i / $max ))
        blue=$(( $start_blue + ($end_blue - $start_blue) * $i / $max))
        set_color "$light" "$red" "$green" "$blue"
        sleep $sleep
        i=$(($i + $step))
    done
    echo
    # $red, $green and $blue are global variables and will be available to the
    # caller after this function exits. The values may differ from the input
    # end values if a step other than one is chosen. Because of that, these
    # values are useful for subsequent calls as new start values to continue
    # an earlier fade or to reverse fade back to a previous start value.
}

# demos (produces a lot of output)

# fade LED, step, sleep, start R G B, end R G B
#fade one 3 0 100 200 15 154 144 200
#fade one 3 0 "$red" "$green" "$blue" 100 200 15
#fade two 1 1 30 40 50 70 20 10
#fade three 1 0 0 255 0 0 0 255

#printf "\n------\n%s:%s:%s => %s:%s:%s\n------\n\n" 255 0 0 34 255 0

#255;0;0 to 255;255;0 to 0;255;0


#fade one 4 0 255 255 245 255 249 180
#fade one 4 0 255 249 180 255 129 116
#fade one 3 0 255 129 116 251 27 4

# POSITIVE COLORS
#echo "A"
# fade one 4 0 255 255 245 255 242 170
# #echo "B"
# fade one 1 0 255 242 170 248 132 78 
# #echo "C"
# fade one 3 0 248 132 78 165 0 38

#exit
# echo "White"
# fade one 1 0 255 255 228 255 255 245


# fade one 2 0 96 150 197 223 244 248
# echo
# fade one 2 0 223 244 248 253 188 110
# echo
# fade one 2 0 253 188 110 165 0 39

fade one 2 0 140 51 0 255 119 41

fade one 2 0 178 150 0 255 227 62

fade one 2 0 0 137 96 83 255 203

fade one 2 0 0 75 175 83 157 225

fade one 2 0 152 0 175 233 91 255
exit
# white to yellow
fade one 8 0 255 255 255 255 249 0

fade one 8 0 255 249 0 255 0 0
exit
fade one 1 0 96 150 197 49 54 150
exit
#echo "light blue"
fade one 2 0 255 255 245 131 185 216
#echo "FROM LIGHT BLUE TO BLUE"
fade one 2 0 131 185 216 49 54 149
#echo "Darker blue"
fade one 1 0  49 54 149 33 37 104
exit

# 166 0 38 
# 235 90 60
# 249 189 111
# 253 256 193
echo "From RED to ORANGE:"
#fade one 4 0 165 0 38 252 169 94
fade one 4 0 166 0 38 235 90 60



echo "From ORANGE to YELLOW:"
#fade two 2 0 252 169 94 242 244 226
fade two 2 0 235 90 60 249 189 111


echo "From YELLOW to WHITE:"
# fade two 1 0 249 253 203 248 248 248
fade two 1 0 249 189 111 255 255 228

#exit
#echo "From YELLOW to OFF WHITE"
#fade one $step 0  255 248 179 236 248 228
#printf "\n\n------\n\n"

# 49 54 149
# 131 185 216
# 233 247 230





echo "FROM OFF WHITE TO LIGHT BLUE"
#fade one 2 0 248 248 248 155 204 226
fade one 2 0 233 247 230 131 185 216
echo "FROM LIGHT BLUE TO BLUE"
fade one 3 0 131 185 216 49 54 149
#fade one 3 0 155 204 226 49 54 150


echo "FROM BLUE TO DARKER BLUE"
#fade one 4 0  49 54 150 33 37 104
printf "\nDONE\n\n"

exit
i=0
while [ "$i" -lt 10 ]
do
    set_color one 255 0 0
    set_color two 0 255 0
    set_color three 0 0 255
    sleep 2
    set_color one 0 255 0
    set_color two 0 0 255
    set_color three 255 0 0
    sleep 2
    set_color one 0 0 255
    set_color two 255 0 0
    set_color three 0 255 0
    sleep 2
    i=$(($i + 1))
done