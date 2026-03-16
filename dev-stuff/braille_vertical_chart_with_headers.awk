#!/usr/bin/env gawk -f

@include "./includes/awk/variables.awk";
@include "./includes/awk/functions.awk";

#gawk --include "./includes/awk/functions.awk" 'BEGIN{ printf("Foo bar\tbazsasdfa..."); go2col(6); printf("Tester\n");}'
BEGIN {
    make_chars("superset");
    make_chars("subset");
    make_chars("small");

    #print get_cur_pos()
    update_timestamp();
    term_height = terminal_lines();
    max_value = 0;
    value_limit = (100/5);
    max_rows = value_limit;

    symbols["percent"] = "﹪";
    symbols["empty"] = " ";
    symbols["end"] = "⸌";
    symbols["horizontal_line"] = "⏉";
    symbols["vertical_line"] = "⏐";
    symbols["left_graph_boundary"] = "⎧";
    symbols["header_mapping_vertical"] = "｜";


}
{
    # If this is the first record in the first file, then assume its the headers, and save
    # those for the display labels later.
    if ( FNR == 1 ){
        for ( idx=1; idx<=NF; idx++ ){
            headers[idx] = $idx;
        }
        next;
    }

    # Everything after the first row is chart_data, each column needs to correlate with the
    # headers[] array
    for ( idx=1; idx<=NF; idx++ ){
        if ( $idx > max_value ) {
            max_value = $idx;
        }
        chart_data[idx] = $idx;
    }
}
END {
    # end_char = "⸌"; # ⸌ 𛲃
    # horizontal_line_char = "⏉";
    # vertical_char = "⏐";
    # left_graph_boundary_char = "⎧";
    # header_mapping_vertical_char = "｜";

    for ( col in chart_data ){
        if ( int(chart_data[col]) == 0 ){
            chart_images[col][length(chart_images[col])] = bar_graph_chars[0];
            continue;
        }

        full_images = int(chart_data[col]/5);
        partial_image = int(chart_data[col] % 5);

        if ( full_images > 0 ){
            for ( i = 0; i<full_images; i++){
                chart_images[col][length(chart_images[col])] = bar_graph_chars[5];
            }
        }

        if ( bar_graph_chars[partial_image] ){
            chart_images[col][length(chart_images[col])] = bar_graph_chars[partial_image];
        }
    }

    for ( row_idx = max_rows; row_idx >= 1; row_idx-- ){
        if ( row_idx == 1 ){
            printf("\033[38;5;222;2;3m%s%2s\033[23;38;5;12;2m%s\033[0m", symbols["percent"], to_subset(row_idx*5), symbols["left_graph_boundary"]); #
            #
        }
        else {
            printf("\033[38;5;222;2;3m%4s\033[23;38;5;12;2m%s\033[0m", to_subset(row_idx*5), symbols["left_graph_boundary"]); #
        }
        _row_idx = row_idx; #-1;
        n = length(chart_images);

        for ( col=1; col<=n; col++){
            if ( length(chart_images[col][_row_idx]) == 0 || chart_images[col][_row_idx] == 0 ){
                chart_images[col][_row_idx] = bar_graph_chars[0];
            }
            color = percent_to_color(row_idx*4)
            printf("%s\b\b%s%s", bar_graph_chars[0], color, chart_images[col][_row_idx]);
        }
        printf("%20s\n", " ");
    }

    for ( col_p=0; col_p<=NF; col_p++){
        printf("%5s", " ");
        for ( col=1; col<=NF; col++){
            # The lines tying the base of the chart to the header mapping line
            if ( col_p == 0 ){
               printf("\033[38;5;12;1m%-2s\033[0m", symbols["horizontal_line"]);
               continue;
            }

            # Since for the headers, they will each be the same number of positions down as
            # they are from the left, we can just use that numerical value to determine if/when
            # to sho the header for the column.
            for ( i=1; i<=5; i++){
                 if ( col_p == i && col == NF-(col_p-1) ){
                    label_color = percent_to_color(chart_data[col]);
                    printf("\033[38;5;12;1m%2s\033[0m%s %s\033[2;3m%s\033[0m", symbols["end"], to_small(headers[col]), label_color, to_small("("chart_data[col]"%)"));
                    break;
                }
            }

            # The bottom horizontal line of the chart (0%)
            # Also is the beginning of the columns mapping
            # to the header (T)
            if ( col < NF-(col_p-1) ){
                printf("\033[38;5;12;2m%s\033[0m", symbols["header_mapping_vertical"]);
                continue;
            }

            printf("\033[38;5;12;2m%2s\033[0m", symbols["empty"]);
        }
        printf("\n");
    }

    # Clear the rest of the output (may still be some left there from a previous execution)
    #printf("\033[J");


    # #printf("CP: %s\n",cp)
    # printf("arr[1]: %s\n",arr[1])
    # printf("arr[2]: %s\n",arr[2])
}
# Who writes this much awk?! A weirdo, that's who.