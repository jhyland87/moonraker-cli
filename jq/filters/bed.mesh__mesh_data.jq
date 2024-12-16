# Gogic for gatherng the useful data from the mesh response data
#
# read -r mesh_profile algorythm mesh_min mesh_max probed_matrix mesh_matrix mesh_highest mesh_lowest mesh_range std_deviation variance \
#   <<< $(jq -f jq/filters/bed.mesh__mesh_data.jq --raw-output "${TMP_DIR}/bed_mesh.tmp.json")
# echo $mesh_profile $algorythm $mesh_min $mesh_max $probed_matrix $mesh_matrix $mesh_highest $mesh_lowest $mesh_range $std_deviation $variance
# default lagrange        5/5     215/215 5x5     13x13   0.877531        -0.087469       0.965   0.22479 0.05053
#

include "./jq/utils";

(.result.status.bed_mesh | [
    # Name for currently active profile mesh
    .profile_name,
    # Mesh parameters for current mesh profile
    (.profiles[.profile_name].mesh_params | (
        # Algorythm
        .algo,
        # Mesh minimum
        ([float_to_int(.min_x), float_to_int(.min_y)] | join("/")), 
        # Mesh maximum
        ([float_to_int(.max_x), float_to_int(.max_y)] | join("/")),
        # Bed mesh size
        ([.x_count,.y_count] | join("x"))
    )),
    # Calculated mesh matrix stuff
    (.mesh_matrix | (
        # Mesh probe size
        (length as $x | .[0] | length as $y| [$x,$y] | join("x")),
        # Mesh probe values processing
        ([.[][]] | (sort_by(.) | (
            # Mesh max and min values
            .[-1], .[0],
            # Range
            (.[-1]+(-.[0]) | trim_num(7)), 
            # Standard deviation
            calc_std_deviation(true), 
            # Variance
            calc_variance(true) 
        )))
    ))
]) | join("\t")