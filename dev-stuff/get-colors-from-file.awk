#!/usr/bin/env gawk -f 


BEGIN {
    negative_colors["xxxx"]=""
    while(getline < "dev-stuff/negative-colors.list") {
        negative_colors[length(negative_colors)-1] = $1
        #print $1
    };
    delete negative_colors["xxxx"];

    print "negative_colors", length(negative_colors)


    positive_colors["xxxx"]=""
    while(getline < "dev-stuff/positive-colors.list") {
        positive_colors[length(positive_colors)-1] = $1
        #print $1
    };
    delete positive_colors["xxxx"];
    
    print "positive_colors", length(positive_colors)
}