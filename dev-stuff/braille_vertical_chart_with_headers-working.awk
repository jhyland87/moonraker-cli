#!/usr/bin/env gawk -f 
#     ｜
# ＼｜ￜ｜ﾤ￣
# echo "2 1 7 1" | ./dev-stuff/braille_vertical_chart.awk
# _rand(){ for i in $(seq 1 $1); do echo -n "$((RANDOM/3000)) "; done; }
# while :; do tput clear; _rand 5 | ./dev-stuff/braille_vertical_chart.awk; sleep 0.1; done
@include "./includes/awk/variables.awk";
@include "./includes/awk/functions.awk";

function make_label(label){
    if ( label == "LOAD%" ) return "ʟᴏᴀᴅ﹪";
    if ( label == "MEM%" ) return "ᴍᴇᴍ﹪";
    if ( label == "CPU" ) return "ᴄᴘᴜ";
    if ( label == "CPU0" ) return "ᴄᴘᴜ₀";
    if ( label == "CPU1" ) return "ᴄᴘᴜ₁";
    return
}

BEGIN {
    # printf("\n\n\t\t   ")
    # get_cursor_pos(pos)
    # printf("X: %d;Y: %d", pos[1],pos[2])

    update_timestamp();
    max_rows = terminal_lines();
    #max_rows = max_rows
    max_value = 0;
    value_limit = (100/4);
    max_rows = value_limit;
    make_chars("superset");
    make_chars("subset");
    make_chars("small");
}
{   
    if ( NR == 1 ){
        for ( idx=1; idx<=NF; idx++ ){
            headers[idx] = $idx
        }
        next
    }
    for ( idx=1; idx<=NF; idx++ ){
        #idx = i+1
        #idx = i;
        #if ( $idx > value_limit ) continue;

        if ( $idx > max_value ) max_value = $idx;

        chart_data[idx] = int($idx);
    }
}

#echo "⎜ ⎟ ⎢ ⎥ ⎪ ⎮ ⎸ ⎹ ⏐ ⏽ | ⏐ ⼁ ｜" | tr ' ' '\n' | while read c; do printf "\n\e[1m%-2s\e[0m" "⏉"; printf "\n%3s" $c; printf "\n%-2s" $c; printf "\n%-4s\n" "᭥"; done; 

#echo "| ⏐ ｜ ⎸ ⎹ ⏐ ︳ ⼁ ｜ 𐀅"| tr ' ' '\n' | while read c; do printf "\n\e[1m%-2s\e[0m" "⏉"; printf "\n%3s" $c; printf "\n%-2s" $c; printf "\n%4s\n" "᭥"; done; 

END {
    end_char = "𛲃"; # ᭥ 𛲃 `
    top_char = "";
    horizontal_line_char = "⏉";
    vertical_char = "⏐"; # |
    left_graph_boundary_char = "⎾"; # ⎧⎰
    top_char = "｜";
    
    for ( col in chart_data ){
        if ( chart_data[col] == 0 ){
            chart_images[col][length(chart_images[col])] = "⠀⠀";
            continue;       
        }

        full_images = int(chart_data[col]/4);
        partial_image = int(chart_data[col] % 4);

        if ( full_images > 0 ){
            for ( i = 0; i<full_images; i++){
                chart_images[col][length(chart_images[col])] = "⣿⡇"; # ⣿⡇
            }
        }
        
        if ( partial_image == 1 )  chart_images[col][length(chart_images[col])] = "⣀⡀"; # ⣀⡀
        if ( partial_image == 2 )  chart_images[col][length(chart_images[col])] = "⣤⡄"; # ⣤⡄
        if ( partial_image == 3 )  chart_images[col][length(chart_images[col])] = "⣶⡆"; # ⣶⡆
    }

    for ( row_idx = max_rows; row_idx >= 1; row_idx-- ){
        printf("\033[38;5;222;2m%3s\033[38;5;12;2m%s\033[0m", to_subset(row_idx*4), left_graph_boundary_char); # 
        _row_idx = row_idx; #-1;
        n = length(chart_images);

        for ( col=1; col<=n; col++){
            if ( length(chart_images[col][_row_idx]) == 0 || chart_images[col][_row_idx] == 0 ){
                chart_images[col][_row_idx] = "⠀⠀";
            }

            color = percent_to_color(row_idx*4)

            printf("%s%s", color, chart_images[col][_row_idx]);
        }
        printf("\n");
    }

    #printf("%4s", " ");

    for ( col=1; col<=NF; col++){
        # ⎡ T ｢ ᴸ⌞﹂⎣ ｰￚＴ－￣⌞﹂ᴸ𝖫｢﹣𛲃𛲆
        # I
        # ⎸
        # |
        # ⎸
        # ⎹
        # ⏐
        # ⎿
        # │
        # ︱
        # ￨
        # ｜
        # ︳
        # ᵀＴ𝖳𝗧Ṭ𝖳
        # ꜖꜒⥡⥝⇃꜖꜒⥡⥝⇃
        # ⎾⎸⎹|
        # ⎿⎹⏐︳𑗅
        #printf("\033[38;5;12;2m%2s\033[0m", top_char);
    }
    
    for ( col_p=0; col_p<=NF; col_p++){
        printf("%4s", " ");
        for ( col=1; col<=NF; col++){
            if ( col_p == 0 ){
               printf("\033[38;5;12;1m%-2s\033[0m", horizontal_line_char);
               continue
            }
            if ( col_p == 1 && col == NF-(col_p-1) ){
                printf("\033[38;5;12;2m%2s\033[0m%s", end_char, to_small(headers[col]));
                continue;
            }

            if ( col_p == 2 && col == NF-(col_p-1) ){
                printf("\033[38;5;12;2m%2s\033[0m%s", end_char, to_small(headers[col]));
                continue;
            }

            if ( col_p == 3 && col == NF-(col_p-1) ){
                printf("\033[38;5;12;2m%2s\033[0m%s", end_char, to_small(headers[col]));
                continue;
            }

            if ( col_p == 4 && col == NF-(col_p-1) ){
                printf("\033[38;5;12;2m%2s\033[0m%s", end_char, to_small(headers[col]));
                continue;
            }

            if ( col_p == 5 && col == NF-(col_p-1) ){
                printf("\033[38;5;12;2m%2s\033[0m%s", end_char, to_small(headers[col]));
                continue;
            }

            if ( col < NF-(col_p-1) ){
                printf("\033[38;5;12;2m%s\033[0m", top_char);
                continue;
            }

            printf("\033[38;5;12;2m%2s\033[0m", " ");
        }
        printf("\n")
    }
}
        # I| ⎸ ⎹⏐⎿│︱￨｜︳