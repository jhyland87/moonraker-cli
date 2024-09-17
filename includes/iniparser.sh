
# get_printer_cfg_val $1 $2 $3
get_printer_cfg_val(){
    local printer=$1

    ! test -f ./config/printers/${printer}.cfg && 
        echo "No config found at ./config/printers/${printer}.cfg" 1>&2 && 
        return 1

    
    local group=$2
    local setting=$3
    
    gawk -F '[ ]=[ ]' -v group=${group} -v setting=${setting} -f ./includes/iniparser.awk ./config/printers/${printer}.cfg
}

