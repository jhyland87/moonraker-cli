#!/usr/bin/env gawk -f 
# 
# DESCRIPTION
#   Calculates the standard deviation and variance for a set of numbers
# 
# SEE
#   https://www.calculatorsoup.com/calculators/statistics/standard-deviation-calculator.php
#
# TODO
#   Currently this only generates the "population" standard deviation. It should be made to
#   also work with just samples
#
# EXAMPLE USAGE
#   curl http://192.168.0.96:7125 \
#    --request GET \
#    --request-target /printer/objects/query \
#    --data bed_mesh=mesh_matrix \
#    --silent \
#    | jq --raw-output '.result.status.bed_mesh.mesh_matrix | reverse | .[] | @csv' \
#    | ./includes/awk/standard-deviation.awk 
# 0.434172
#
# jq --raw-output '.result.status.bed_mesh.mesh_matrix | reverse | .[] | @csv' | ./includes/awk/standard-deviation.awk 
#

@include "./includes/awk/functions.awk";

BEGIN {
    FS=",";
}
{
    COL_COUNT = NF; # Number of fields in current row (aka: columns)

    # Adding a new row between each row. row*2-1 gets the new ID spacing
    # While iterating over the columns for this line, well also inject the new averaged values for the new columns and rows.
    for ( col_idx = 1; col_idx <= COL_COUNT; col_idx++ ){
        # Size/count needed for calcs
        sd_count++;

        # Sum (also needed)
        sd_sum += $col_idx;

        # Store the value, since this will be needed when calculating the 
        sd_all_values[sd_count-1] = $col_idx;
    }
}
END {
    # Calculate the mean for population (𝜇)
    sd_mean = sd_sum/sd_count;

    # Sample
    #sd_variance = sd_sum/(sd_count-1)

    # Variance (𝜎)
    sd_variance = sd_sum/(sd_count);

    for ( idx in sd_all_values ){
        value = sd_all_values[idx]-sd_mean;
        # 𝑆𝑆
        sd_sumofsquares += value*value; 
    }

    # Variance squared (𝜎²)
    sd_variance = (sd_sumofsquares/(sd_count-1));

    # Standard deviation for population (𝜎)
    sd_value = sqrt(sd_variance);

    # Result!
    print sd_value;
}