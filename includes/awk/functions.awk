# Average two numbers.
function avg(a, b){
    return (a+b)/2;
}

# function round(x, ival, aval, fraction){
#    ival = int(x)    # integer part, int() truncates

#    # see if fractional part
#    if (ival == x)   # no fraction
#       return ival   # ensure no decimals

#    if (x < 0) {
#       aval = -x     # absolute value
#       ival = int(aval)
#       fraction = aval - ival
#       if (fraction >= .5)
#          return int(x) - 1   # -2.5 --> -3
#       else
#          return int(x)       # -2.3 --> -2
#    } else {
#       fraction = x - ival
#       if (fraction >= .5)
#          return ival + 1
#       else
#          return ival
#    }
# }

function round(num){
    return sprintf("%.f", int(num+0.5));
}

# Get the absolute value (positive value) of a number.
# abs(123)  = 123
# abs(-123) = 123
function abs(num){
    if ( num < 0 ) 
        return -num;

    return num;
}

function float(number){
    return sprintf("%2.3f",number)
}

# Adding a new row between each row. row*2-1 gets the new ID spacing
# 1*2-1 = 1
# 2*2-1 = 3
# 3*2-1 = 5... etc
function get_new_idx(id){
    return id*2-1;
}

# Set the foreground color.
function fg(color){
    printf("\033[38;2;%sm", color);
}

# Set the background color.
function bg(color){
    printf("\033[48;2;%sm", color);
}

# Function to send the cursor to a specific location of the current line.
function go2col(col) {
    printf("%s", sprintf("\033[100D\033[%sC", col));
}

# Trim a number to a specific length. This will include the - char if
# this is a negative numerical value.
#
#   trim_gradient(12.345, 5) 
#     12.34
#   trim_gradient(-12.345, 5) 
#     -12.3
function trim_gradient(value, char_len){
    if ( length(char_len) == 0 ) 
        char_len = 5;

    if ( value < 0 ) 
        return substr(value, 0, char_len+1);

    return substr(value, 0, char_len);
}

# Takes a positive value and returns the corresponding gradient color from the
# positive_colors array.
function pos_mesh_val_to_color(mesh_val){
    # Set the min and max values to whichever is the largest absolute value, to keep the gradient
    # scale a bit more consistent.
    if ( abs(min_value) > max_value ) 
        _value_limit = abs(min_value);
    else  
        _value_limit = abs(max_value);

    if ( mesh_val == 0 ) 
        return positive_colors[0];
    
    color_span = (length(positive_colors)-1)/_value_limit;

    if ( length(max_gradient_color_span) > 0 && color_span > max_gradient_color_span ) 
        color_span = max_gradient_color_span;
    
    # If the color span breaches the max_gradient_color_span, then set the color_span
    # to max_gradient_color_span
    if ( length(max_gradient_color_span) > 0 && color_span > max_gradient_color_span ) 
        color_span = max_gradient_color_span;

    if ( mesh_val > _value_limit ) 
        mesh_val = _value_limit;
    
    idx = int(mesh_val * color_span);

    return positive_colors[idx];
}

# Takes a negative value and returns the corresponding gradient color from the
# negative_colors array.
# Note: the negative and positive gradients are in separate arrays because there
# are likely different amounts/deviations between the positive and negative values.
function neg_mesh_val_to_color(mesh_val){
    # Set the min and max values to whichever is the largest absolute value, to keep the gradient
    # scale a bit more consistent.
    if ( abs(min_value) < max_value ) 
        _value_limit = abs(min_value);
    else 
        _value_limit = abs(max_value);


    # color_span - mesh_values within this range will get the same color returned.
    # This is just used to determine what mesh value ranges go to what colors.
    color_span = (length(negative_colors)-1)/_value_limit;

    if (length(max_gradient_color_span) > 0 && color_span < max_gradient_color_span ) 
        color_span = max_gradient_color_span;

    #print "negative mesh_val",mesh_val
    if ( mesh_val == 0 || mesh_value < -color_span ) 
        return negative_colors[0];

    # If the color span breaches the max_gradient_color_span, then set the color_span
    # to max_gradient_color_span
    if ( length(max_gradient_color_span) > 0 && color_span < -max_gradient_color_span ) 
        color_span = -max_gradient_color_span;

    if ( mesh_val < -_value_limit )  
        mesh_val = -_value_limit;

    idx = int(mesh_val * color_span);
    idx = abs(idx)

    return negative_colors[idx];
}

# Takes a positive or negative numerical value and returns the corresponding mesh
# color using eiher pos_mesh_val_to_color or neg_mesh_val_to_color
function mesh_val_to_color(mesh_val){
    if ( mesh_val == 0 )  
        return positive_colors[0];

    if ( mesh_val < 0 )  
        return neg_mesh_val_to_color(mesh_val);
        
    return pos_mesh_val_to_color(mesh_val);
}


# Takes a string and tries to substitute each character with the subset char
# if it is found in the char_set["subset"] string.
function to_subset(string){
    char_count = split(string, chars, "");
    res = "";

    for ( char_idx in chars )
        res = sprintf("%s%s", res, charset_maps["subset"][chars[char_idx]]);

    return res;
}

# Takes a string and tries to substitute each character with the superset char
# if it is found in the char_set["superset"] string.
function to_superset(string){
    char_count = split(string, chars, "");
    res = "";

    for ( char_idx in chars )
        res = sprintf("%s%s", res, charset_maps["superset"][chars[char_idx]]);

    return res;
}

# Takes the values in char_set array, splits them into separate characters, and
# maps them to their corresponding values. The new mapping will be stored in a
# newly created value in the charset_maps hash.
function make_chars(char_group){
    for ( i=1; i <= length(char_set[char_group]); i++ ) {   
        key = substr(char_set["normal"],i,1);
        val = substr(char_set[char_group],i,1);

        charset_maps[char_group][key] = val;
    }
}
