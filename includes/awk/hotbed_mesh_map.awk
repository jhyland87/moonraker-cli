#!/opt/homebrew/bin/gawk -f
# 
# DESCRIPTION
#   Generates a neat looking heatmap of the bed mesh from Klippers API output.
#
# TODO
#   Currently this works for a 12/12 bed mesh, but it should be written so it'll
#   work with any mesh size. The X/Y indicators, arrows and gradient scale on the
#   right will probably be broken on different bed mesh scales.
#
# EXAMPLE USAGE
#   curl http://192.168.0.96:7125 \
#       --request GET \
#       --request-target /printer/objects/query \
#       --data bed_mesh=profile_name,probed_matrix,mesh_matrix,profiles \
#       --connect-timeout 5 \
#       --silent \
#       | jq --raw-output '.result.status.bed_mesh.mesh_matrix | reverse | .[] | @csv' \
#       | ./hotbed_to_expanded_mesh.awk
#

@include "./includes/awk/variables.awk";
@include "./includes/awk/functions.awk";

BEGIN {
    FS=",";
    make_chars("superset");
    make_chars("subset");
}
{
    COL_COUNT = NF; # Number of fields in current row (aka: columns)
    ROW_COUNT = NR; # Current row number of current file

    # Adding a new row between each row. row*2-1 gets the new ID spacing
    new_row_idx = get_new_idx(ROW_COUNT);

    # While iterating over the columns for this line, well also inject the new averaged values for the new columns and rows.
    for ( col_idx = 1; col_idx <= COL_COUNT; col_idx++ ){
        #sd_count++
        #sd_sumofmesh+=$col_idx
        ##sd_sumofsquares+=($col_idx*sd_count)-(sd_count*sd_count)
        #sd_all_values[sd_count-1]=$col_idx

        # Saving the highest and lowest mesh values so we know how to scale the colors
        if ( length(min_value) == 0 || $col_idx < min_value ) 
            min_value = $col_idx;

        if ( length(max_value) == 0 || $col_idx > max_value ) 
            max_value = $col_idx;

        new_col_idx = get_new_idx(col_idx);
        last_new_col_idx = new_col_idx-1;
        current_mesh_value = $col_idx;

        # If this is after the first column, then generate/save the synthetic column value in the cell behind this one.
        if ( col_idx > 1 ){
            # Grab the cdll 2 cells away (since the enpty synthetic col is there), and average it with this one.
            #current_row_last_synthetic_column = avg(results[new_row_idx][new_col_idx-2], current_mesh_value);
            results[new_row_idx][new_col_idx-1] = avg(results[new_row_idx][new_col_idx-2], current_mesh_value);

            # If were past the first row, then we can also generate the averaged values for the synthetic value one column/row behind
            if ( ROW_COUNT > 1)
                #results[new_row_idx-1][new_col_idx-1] = avg(current_row_last_synthetic_column, results[new_row_idx-2][new_col_idx-1]);
                results[new_row_idx-1][new_col_idx-1] = avg(results[new_row_idx][new_col_idx-1], results[new_row_idx-2][new_col_idx-1]);

                
        }

        results[new_row_idx][new_col_idx] = current_mesh_value;

        if ( ROW_COUNT > 1){
            #last_synthetic_row_current_column_value = avg(current_mesh_value, results[new_row_idx-2][new_col_idx]);
            results[new_row_idx-1][new_col_idx] = avg(current_mesh_value, results[new_row_idx-2][new_col_idx]);
        }

        last_mesh_val = current_mesh_value;
    }
}
END {
    # sd_mean=sd_sumofmesh/sd_count
    # sd_variance=sd_sumofmesh/(sd_count-1)

    # for ( v in sd_all_values ){
    #     s=sd_all_values[v]-sd_mean
    #     sq=s*s;
    #     sd_sumofsquares+=s*s
    # }

    # sd_variance=(sd_sumofsquares/(sd_count-1))
    # sd_value=sqrt(sd_variance)
    # print sd_value


    positive_gradient_scale_spacing = max_value/(ROW_COUNT-1);
    negative_gradient_scale_spacing = min_value/(ROW_COUNT-1);
    gradient_scale_cursor = max_value;

    coordinates_y_center = ROW_COUNT;

    if ( coordinates_y_center % 2 == 1 ) 
        coordinates_y_center++;

    coordinates_y_top = coordinates_y_center-4;
    coordinates_y_bottom = coordinates_y_center+4;

    # Print first row in X axis coordinate rows if any double digit cols are found. 
    # This will print the numbers like:
    #                 1  1  1
    #  1  2  3 ... 9  0  1  2 ...
    if ( length(COL_COUNT) > 1 ){
        printf("%s", go2col(grid_start_indent));
        for ( i = 0; i<=(COL_COUNT-1); i++){
            col_num = i;
            if ( length(col_num) > 1 ){
                split(col_num, col_num_arr, "");
                printf("%s%-"(grid_start_indent-1)"s\033[0m", colors["xy"], to_subset(col_num_arr[1]));
            }
            else {
                printf("%s%-"(grid_start_indent-1)"s\033[0m", colors["xy"],  " ");
            }
        }
        printf("\n");
    }

    # Print second row in X axis coordinate rows, if any double digit cols are found
    printf("%s", go2col(grid_start_indent));

    for ( i = 0; i<=(COL_COUNT-1); i++){
        col_num = i;
        if ( length(col_num) > 1 ){
            split(col_num, col_num_arr, "");
            col_num = col_num_arr[2];
        }
        printf("%s%-"(grid_start_indent-1)"s\033[0m", colors["xy"], to_superset(col_num));
    }
    printf("\n");

    row_idx_display = 0;

    # Iterating over each row...
    for (row in results){
        # Iterating over each cell in this row.
        for (col in results[row]){

            # Print the Y axis coordinates on the first row then every other row after that.
            if ( col == 1 && (row %2 == 0 || row == length(results)) ){
                printf("%s%2s\033[0m", colors["xy"], to_superset(row_idx_display));
                printf("%s", go2col(grid_start_indent));
                row_idx_display++;
            }

            # Print the 2nd row of cells. These are all just created by averaging the surrounding
            # values (to make for a larger heat map).
            if ( row % 2 == 1 ){
                if ( row == length(results) ){
                    printf("\033[38;2;%sm%s\033[0m", mesh_val_to_color(results[row][col]), block["upper"]);
                    continue;
                }

                previous_row_colors[col] = mesh_val_to_color(results[row][col]);
                continue;
            }
            
            printf("\033[38;2;%s;48;2;%sm%s\033[0m", mesh_val_to_color(results[row][col]), previous_row_colors[col], block["lower"]);
        }
        
        # Logic to show the Y coordinates and arrows
        if ( row == coordinates_y_top )
            printf("%s%2s\033[0m", colors["coordinates"], coordinates["up"]);
        else if ( row == coordinates_y_center )
            printf("%s%2s\033[0m", colors["coordinates"], coordinates["Y"]);
        else if ( row == coordinates_y_bottom )
            printf("%s%2s\033[0m", colors["coordinates"], coordinates["down"]);
        
        if ( row % 2 == 0  ) {
            top_color = mesh_val_to_color(gradient_scale_cursor);
            top_val = gradient_scale_cursor;

            if ( gradient_scale_cursor >= 0 )
                gradient_scale_cursor = gradient_scale_cursor - positive_gradient_scale_spacing;
            else 
                gradient_scale_cursor = gradient_scale_cursor + negative_gradient_scale_spacing;
            
            bottom_color = mesh_val_to_color(gradient_scale_cursor);
            bottom_val = gradient_scale_cursor;

            if ( gradient_scale_cursor >= 0 )
                gradient_scale_cursor = gradient_scale_cursor - positive_gradient_scale_spacing;
            else 
                gradient_scale_cursor = gradient_scale_cursor + negative_gradient_scale_spacing;

            printf("\t\033[38;2;%s;48;2;%sm%s%s\033[0m %s\n", bottom_color, top_color, block["lower"], block["lower"], to_superset(trim_gradient(top_val)));
        }
        else if (row == length(results)) {
            printf("\t\033[38;2;%sm%s%s\033[0m %s\n", mesh_val_to_color(results[row][col]),  block["upper"], block["upper"],  to_superset(trim_gradient(min_value)));
        }
    }

    # Logic to show the X coordinates and arrows
    printf("%s%s%-3s %s %3s%s\n", go2col(10), colors["coordinates"], coordinates["left"], coordinates["X"], coordinates["right"], "\033[0m");

    #sd_mean=sd_sumofmesh/sd_count
    #sd_variance=sd_sumofmesh/(sd_count-1)
    
    # printf("sd_count: %s\n", sd_count)
    # printf("sd_sumofmesh: %s\n", sd_sumofmesh)
    # #printf("sd_sumofsquares: %s\n", sd_sumofsquares)
    # printf("sd_mean: %s\n",sd_mean)
    # printf("sd_variance: %s\n",sd_variance)


    # for ( v in sd_all_values ){
    #     #s=( abs(sd_all_values[v])-sd_mean)-sd_mean
    #     s=sd_all_values[v]-sd_mean
    #     sq=s*s
    #     sd_sumofsquares+=s*s
    #     #printf("%s| %s: %s-%s = %s; squared: %s; sd_sumofsquares: %s\n", v, sd_all_values[v], sd_all_values[v], sd_mean, s, sq, sd_sumofsquares)
    #     #print v, sd_all_values[v], (abs(sd_all_values[v])-sd_mean)-sd_mean
    # }

    # print sd_sumofsquares

    # sd_variance=(sd_sumofsquares/(sd_count-1))
    # print sd_variance
    # sd_value=sqrt(sd_variance)
    # print sd_value


    #deviation_from_x= (abs(value)-mean)-mean = (-0.163969-0.209699)-0.209699 = 

    
}