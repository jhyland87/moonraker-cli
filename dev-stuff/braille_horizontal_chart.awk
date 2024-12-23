#!/usr/bin/env gawk -f 


# 18 16 15 17
BEGIN {
    cmd = "tput lines";
    cmd | getline max_lines;
    close(cmd);

    print "Result:",result;
}
{
    COL_COUNT = NF; # This will be the number of rows output
    ROW_COUNT = NR; # Current row number of current file

   # print COL_COUNT
    # While iterating over the columns for this line, well also inject the new averaged values for the new columns and rows.
    for ( col_idx = 1; col_idx < (COL_COUNT+1); col_idx++ ){
        #_idx = col_idx
        #printf("%d = %d\n", _idx, $_idx)
        graph_rows[col_idx] = $col_idx
    }
    
}
END {


    for ( c in graph_rows ){
        printf("%d = %d\n", c, graph_rows[c])
    }
}