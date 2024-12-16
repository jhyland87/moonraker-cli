#!/usr/bin/env gawk -f 
# 
# DESCRIPTION
#   Generates a neat looking heatmap of the bed mesh from Klippers API output.
#   This works by using the full width half block unicode character (▄) to compine
#   two rows into a single row. Row #0 will be iterated over, saving the colors and 
#   data to an array, then as row #1 is processed, the half-block character will use
#   the color meant for row #0 as the background (top) color and the the color for 
#   row #2 on the bottom.
#   This does result in a much smaller mesh display which can be enlarged a bit by
#   inserting "synthetic" columns and rows inbetween each row/column, then averaging
#   the values on either side of the cell as they're being processed.
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
# jq --raw-output '.result.status.bed_mesh.mesh_matrix | reverse | .[] | @csv' ./tmp/bed_mesh.tmp.json" | ./includes/awk/hotbed_mesh_map.awk
#

@include "./includes/awk/variables.awk";
@include "./includes/awk/functions.awk";

BEGIN {
    print "POSITIVE COLORS"
    asort(positive_colors, positive_colors2, "@val_num_desc") 

    for(i = length(positive_colors2); i > 0; i-- ){
        printf("%3s \033[48;2;%sm%-12s\033[0m\n", i-1, positive_colors[i-1], "  ")
    }
    # for ( color in positive_colors2 ){
    #     printf("%3s \033[48;2;%sm%-12s\033[0m\n", color-1, positive_colors[color-1], positive_colors[color-1])
    # }

    print "NEGATIVE COLORS"
     for ( color in negative_colors ){
        printf("%3s \033[48;2;%sm%-12s\033[0m\n", color, negative_colors[color], "  ")
    }
   
}