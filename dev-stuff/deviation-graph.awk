#!/opt/homebrew/bin/gawk -f
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


# jq --raw-output '.result.status.bed_mesh.mesh_matrix | reverse | .[] | @csv' ./tmp/bed_mesh.tmp.json | ./dev-stuff/deviation-graph.awk

@include "./includes/awk/functions.awk";
@include "./includes/awk/variables.awk";

BEGIN {
    FS=",";
    make_chars("superset");
    make_chars("subset");
    TRUNCATE_VALS = 4;
}
{
    COL_COUNT = NF; # Number of fields in current row (aka: columns)
    all_values[0]=0
    # Adding a new row between each row. row*2-1 gets the new ID spacing
    # While iterating over the columns for this line, well also inject the new averaged values for the new columns and rows.
    for ( col_idx = 1; col_idx <= COL_COUNT; col_idx++ ){
        is_neg = ( $col_idx < 0 );

        if ( is_neg ){
            neg_count++;

            _value = abs($col_idx);

            all_values[_value] = _value

            neg_value_collection[0] = 0
            neg_value_collection[length(neg_value_collection)] = _value ;


            if ( _value > neg_max ){
                neg_max =_value;
            }
            else if (_value < neg_min ){
                neg_min = _value;
            }
        }
        else {
            pos_count++;

            all_values[$col_idx] = $col_idx

            pos_value_collection[0] = 0
            pos_value_collection[length(pos_value_collection)] = $col_idx;

            if( $col_idx > pos_max ){
                pos_max = $col_idx
            }
            else if ($col_idx < pos_min){
                pos_min = $col_idx
            }
        }



        # # Size/count needed for calcs
        # sd_count++;

        # # Sum (also needed)
        # sd_sum += $col_idx;

        # # Store the value, since this will be needed when calculating the 
        # sd_all_values[sd_count-1] = $col_idx;
    }
}
END {

    print "pos_count", pos_count
    print "pos_max", pos_max
    print "pos_min", pos_min
    print "neg_count", neg_count
    print "neg_max", neg_max
    print "neg_min", neg_min

    n = asort(neg_value_collection, neg_value_collection_sorted)
    p = asort(pos_value_collection, pos_value_collection_sorted)
    print "neg_value_collection", length(neg_value_collection)

    
    rounded_values[0]=0
    neg_max_occurrences = 1;
    pos_max_occurrences = 1;
    
    for ( v in all_values ){
        val_rounded = substr(all_values[v], 0, TRUNCATE_VALS);
        #print v, all_values[v], val_rounded
        rounded_values[val_rounded] = val_rounded
    }

    asort(rounded_values, sorted_val_rounded);

    #  for (row_height = 5; row_height >= 0; row_height--) {
    #     printf("%5s ", row_height);


    #     for ( v in sorted_val_rounded ){
    #         print v, sorted_val_rounded[v];
    #     }
        

    # }

    for ( idx in neg_value_collection ){ # neg_value_collection_sorted
        neg_rounded = substr(neg_value_collection[idx], 0, TRUNCATE_VALS);

        if ( neg_rounded_collection[neg_rounded] ){
            neg_rounded_collection[neg_rounded]++;

            if ( neg_rounded_collection[neg_rounded] > neg_max_occurrences )
                neg_max_occurrences = neg_rounded_collection[neg_rounded];
        }
        else {
            neg_rounded_collection[neg_rounded] = 1;
        }
        
        print "\tneg:",idx, neg_value_collection[idx], neg_rounded, neg_max_occurrences
    }

    print "pos_value_collection", length(pos_value_collection)
    for ( idx in pos_value_collection ){
         pos_rounded = substr(pos_value_collection[idx], 0, TRUNCATE_VALS);

        if ( pos_rounded_collection[pos_rounded] ){
            pos_rounded_collection[pos_rounded]++;

            if ( pos_rounded_collection[pos_rounded] > pos_max_occurrences )
                pos_max_occurrences = pos_rounded_collection[pos_rounded];
        }
        else {
            pos_rounded_collection[pos_rounded] = 1;
            #pos_max_occurrences = 1;
        }

        print "\tpos:",idx, pos_value_collection[idx], pos_rounded, pos_max_occurrences
    }

    if ( pos_max > neg_max ){
        gradient_per_ones = (round(pos_max)+1)*5
    }
    else {
        gradient_per_ones = (round(neg_max)+1)*5
    }


    #asorti(pos_rounded_collection, pos_rounded_collection);

    for ( p in pos_rounded_collection ){
        print "p:", p, pos_rounded_collection[p]
    }
    print

      for ( n in neg_rounded_collection ){
        print "n:", n, neg_rounded_collection[n]
    }
    print
    #asorti(neg_rounded_collection, neg_rounded_collection);
    n = asorti(pos_rounded_collection, pos_rounded_collection_2);

    print "sorted_val_rounded", length(sorted_val_rounded)

     for (i = 1; i <= length(sorted_val_rounded); i++) {
        print i, sorted_val_rounded[i]
     }
     
    for (row_height = pos_max_occurrences; row_height >= 0; row_height--) {
        printf("%5s ", to_subset(row_height));

        for (i = 1; i <= length(sorted_val_rounded); i++) {

            occurrances = pos_rounded_collection[sorted_val_rounded[i]];

            if ( occurrances == "" ){
                if ( row_height == 0 ){
                    printf("\033[38;2;%sm%s\033[38;2;0m", "176;20;44", "▁");
                }
                else {
                    printf " ";
                }
                continue;
            }

            mesh_value = pos_rounded_collection_2[i];

            if ( occurrances < row_height ){
                printf " ";
            }
            else if ( occurrances >= row_height ){
                printf("\033[38;2;%sm%s\033[38;2;0m", "176;20;44", "█");
                #printf("\033[38;2;%sm\033[38;2;0m", "176;20;44");
            }
            #print  mesh_value, occurrances
        

        #for ( n in neg_rounded_collection ){
        #   print "n:", n, neg_rounded_collection[n]
        }
        printf "\n"
    }


    n = asorti(neg_rounded_collection, neg_rounded_collection_2);

    
    for (row_height = 0; row_height <= neg_max_occurrences; row_height++) {
        printf("%5s ", to_superset(row_height));

        for (i = 1; i <= length(sorted_val_rounded); i++) {

            occurrances = neg_rounded_collection[sorted_val_rounded[i]];
            #printf("occurrances: %s, %s %s\n", i, sorted_val_rounded[i], occurrances)
            if ( occurrances == "" ){
                 if ( row_height == 0 ){
                    printf("\033[38;2;%sm%s\033[38;2;0m", "55;60;154", "▔");
                }
                else {
                    printf " ";
                }
                continue;
            }

            mesh_value = neg_rounded_collection_2[i];

            if ( occurrances < row_height ){
                printf " ";
            }
            else if ( occurrances >= row_height ){
                printf("\033[38;2;%sm%s\033[38;2;0m", "55;60;154", "█");
            }
            #print  mesh_value, occurrances
        

        #for ( n in neg_rounded_collection ){
        #   print "n:", n, neg_rounded_collection[n]
        }
        printf "\n"
    }

    # # Calculate the mean for population (𝜇)
    # sd_mean = sd_sum/sd_count;

    # # Sample
    # #sd_variance = sd_sum/(sd_count-1)

    # # Variance (𝜎)
    # sd_variance = sd_sum/(sd_count);

    # for ( idx in sd_all_values ){
    #     value = sd_all_values[idx]-sd_mean;
    #     # 𝑆𝑆
    #     sd_sumofsquares += value*value; 
    # }

    # # Variance squared (𝜎²)
    # sd_variance = (sd_sumofsquares/(sd_count-1));

    # # Standard deviation for population (𝜎)
    # sd_value = sqrt(sd_variance);

    # # Result!
    # print sd_value;

    # printf("½\n¾\n⅚\n⅞\n")

    # printf("%-2s %s\n", to_subset(9), "a")
    # printf("%2s %s\n", to_superset(8), "b")
    # printf("%-2s %s\n", to_subset(7), "a")
    # printf("%2s %s\n", to_superset(6), "b")
    # printf("%-2s %s\n", to_subset(5), "a")
    # printf("%2s %s\n", to_superset(4), "b")

    # printf("\n\n")
    # printf("%s%s %s\n", to_superset(9), to_subset(8), "a")
    # printf("%s%s %s\n", to_superset(7), to_subset(6), "b")
    # printf("%s%s %s\n", to_superset(5), to_subset(4), "c")
    # printf("%s%s %s\n", to_superset(3), to_subset(2), "d")
    # printf("%s%s %s\n", to_superset(1), to_subset(0), "e")
}
