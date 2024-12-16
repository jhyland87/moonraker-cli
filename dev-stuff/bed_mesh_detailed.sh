#!/usr/bin/env bash

export TMP_DIR="./tmp"

jq  'include "./jq/utils"; 
        (.result.status.bed_mesh.profile_name) as $profile |
        (.result.status.bed_mesh.profiles[$profile].mesh_params | [
			([.min_x,.min_y] | join("/")), 
			([.max_x,.max_y] | join("/")),
			([.x_count,.y_count] | join("x")),
			.algo
		]) as $mesh_params 
		| (.result.status.bed_mesh.mesh_matrix | [
			([.[][]] | sort_by(.) | .[-1]+(-.[0]) | trim_num(7)),
			(length as $x | .[0] | length as $y| [$x,$y] | join("x")),
            ([.[][]] | calc_std_deviation(true)),
            ([.[][]] | calc_variance(true))
		]) as $matrix_params 
		| [$profile, $mesh_params[], $matrix_params[]] | join(" ")' \
		--raw-output "${TMP_DIR}/bed_mesh.tmp.json"


# jq --arg profile "default" \
# 		'include "./jq/utils"; 
#          [.result.status.bed_mesh.mesh_matrix[][]] | std_deviation' \
#         --raw-output "${TMP_DIR}/bed_mesh.tmp.json"