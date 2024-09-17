#!/opt/homebrew/bin/gawk -f

# $ ./includes/iniparser.sh k1c printer descriptiond  # Returns non-zero (fail) exit code)
# $ ./includes/iniparser.sh k1c printer description   # Successfully found value
# The K1C printer by creality

BEGIN {
    in_group = false;
    match_found = 0;
}
{    
    match($0,/^\[(.*)\]$/, m);
    
    if ( m[1] == group ){
        in_group = true;
        next;
    }

    if (in_group == true && $1 == setting ){
        print $2;
        match_found = 1;
        exit ;
    }
}
END {
    exit match_found != 1;
}
