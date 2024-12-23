
@include "./includes/awk/variables.awk";

function _exec(cmd){
    cmd | getline result;
    close(cmd);
    return result;
}

# Get the # of lines in the terminal
function terminal_lines(){
    return _exec("tput lines");
}

# Get the # of columns in the terminal
function terminal_cols(){
    return _exec("tput cols");
}

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
    if ( num < 0 ) {
        return -num;
    }

    return num;
}

# Just convert a number to a floaty.
# float("1") = 1.000
# float(3.2) = 3.200
function float(number){
    return sprintf("%2.3f",number);
}

# Calculate the standard deviation. This does require the sum total of 
# cell valus to be collected, as well as the cell count.
function calc_sd(){
    return sqrt((1/total_cells)*(total_sum - (((total_sum)^2)/total_cells)))/2;
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

# Trim a number to a specific length. This will include the - char if
# this is a negative numerical value.
#
#   trim_gradient(12.345, 5) 
#     12.34
#   trim_gradient(-12.345, 5) 
#     -12.3
function trim_gradient(value, char_len){
    if ( length(char_len) == 0 ) {
        char_len = 5;
    }

    if ( value < 0 ) {
        return substr(value, 0, char_len+1);
    }

    return substr(value, 0, char_len);
}

# Takes a positive value and returns the corresponding gradient color from the
# positive_colors array.
function pos_mesh_val_to_color(mesh_val){
    # Set the min and max values to whichever is the largest absolute value, to keep the gradient
    # scale a bit more consistent.
    if ( abs(min_value) > max_value ) {
        _value_limit = abs(min_value);
    }
    else {
        _value_limit = abs(max_value);
    }

    if ( mesh_val == 0 ) {
        return positive_colors[0];
    }
    
    color_span = (length(positive_colors)-1)/_value_limit;

    if ( length(max_gradient_color_span) > 0 && color_span > max_gradient_color_span ) {
        color_span = max_gradient_color_span;
    }
    
    # If the color span breaches the max_gradient_color_span, then set the color_span
    # to max_gradient_color_span
    if ( length(max_gradient_color_span) > 0 && color_span > max_gradient_color_span ) {
        color_span = max_gradient_color_span;
    }

    if ( mesh_val > _value_limit ) {
        mesh_val = _value_limit;
    }
    
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
    if ( abs(min_value) < max_value ) {
        _value_limit = abs(min_value);
    }
    else {
        _value_limit = abs(max_value);
    }

    # color_span - mesh_values within this range will get the same color returned.
    # This is just used to determine what mesh value ranges go to what colors.
    color_span = (length(negative_colors)-1)/_value_limit;

    if (length(max_gradient_color_span) > 0 && color_span < max_gradient_color_span ) {
        color_span = max_gradient_color_span;
    }

    #print "negative mesh_val",mesh_val
    if ( mesh_val == 0 || mesh_value < -color_span ) {
        return negative_colors[0];
    }

    # If the color span breaches the max_gradient_color_span, then set the color_span
    # to max_gradient_color_span
    if ( length(max_gradient_color_span) > 0 && color_span < -max_gradient_color_span ) {
        color_span = -max_gradient_color_span;
    }

    if ( mesh_val < -_value_limit ) {
        mesh_val = -_value_limit;
    }

    idx = int(mesh_val * color_span);
    idx = abs(idx);

    return negative_colors[idx];
}

# Takes a positive or negative numerical value and returns the corresponding mesh
# color using eiher pos_mesh_val_to_color or neg_mesh_val_to_color
function mesh_val_to_color(mesh_val){
    if ( mesh_val == 0 ) {
        return positive_colors[0];
    }

    if ( mesh_val < 0 ) {
        return neg_mesh_val_to_color(mesh_val);
    }
        
    return pos_mesh_val_to_color(mesh_val);
}

# Takes a string and tries to substitute each character with the subset char
# if it is found in the char_set["subset"] string.
function to_subset(string){
    return to_charset("subset", string);
}

# Takes a string and tries to substitute each character with the superset char
# if it is found in the char_set["superset"] string.
function to_superset(string){
    return to_charset("superset", string);
}

function to_small(string){
    return to_charset("small", string);
}

# Converts a string into a specified charset.
# This ia executed by the to_small, to_superset and to_subset functions
function to_charset(charset, string){
    char_count = split(string, chars, "");
    res = "";
    for ( cidx in chars ){
        if ( ! charset_maps[charset][chars[cidx]] || charset_maps[charset][chars[cidx]] == " "  ){
            substitute = chars[cidx]
            if ( toupper(chars[cidx]) == chars[cidx] ){
                substitute = toupper(chars[cidx]);
            }
            else if ( toupper(chars[cidx]) == chars[cidx] ){
                substitute = tolower(chars[cidx])
            }

            res = sprintf("%s%s", res, substitute);
            continue;
        }
        
        res = sprintf("%s%s", res, charset_maps[charset][chars[cidx]]);
    }

    return res;
}
# Takes the values in char_set array, splits them into separate characters, and
# maps them to their corresponding values. The new mapping will be stored in a
# newly created value in the charset_maps hash.
function make_chars(char_group){
    normal_group = "normal";
    if ( char_group == "small" ){
        normal_group = "sm_normal";
    }

    for ( char_idx=1; char_idx <= length(char_set[char_group]); char_idx++ ) {   
        key = substr(char_set[normal_group],char_idx,1);
        val = substr(char_set[char_group],char_idx,1);

        charset_maps[char_group][key] = val;
    }
}

function _err(msg){
    print "ERROR:",msg > "/dev/stderr";
    exit 1;
}

function get_epoch(){
    result = _exec("gdate +%s%3N");
    return result;
}

function get_timestamp(fmt){
    if ( ! fmt ) {
        fmt = "%FT%R:%S.%3NZ";
    }
    result = _exec("gdate +"fmt);
    return result;
}

# Save position of curstor to be restored later by restore_cursor()
function save_cursor(){
    printf("\033[s");
}

# Restore the cursor to the position saved when calling save_cursor()
function restore_cursor(){
    printf("\033[u");
}

# NOT WORKING YET
function get_cursor_pos_x(arr){
    #cmd = "IFS=\";\" read -sdRr -p $\"\033[6n\" ROW COL; echo ${ROW#$\"\033\"[}\":\"${COL#$\"\033\"[};"
    cmd = "IFS=';' read -s -p $'\033[6n' ROW COL; echo \"${ROW#$'\033'[}:${col#$'\033'[}\"";
    cmd | getline cursor_pos;
    close(cmd);
    split(cursor_pos, arr, " ");

    printf("%s - \n\tX:%d; Y:%d\n", cursor_pos, arr[1], arr[2]);
}

# NOT WORKING YET
function get_cursor_pos(arr){
    cmd = "IFS=\";\" read -sdR -p $\"\033[6n\"  ROW COL; echo ${ROW#$\"\033\"[}\":\"${COL#$\"\033\"[};";
    cmd | getline cursor_pos;
    close(cmd);
    print("cursor_pos:",cursor_pos);
    split(cursor_pos, arr, ":");
}

# Move cursor to a specific spot on the screen
function move_cursor(x, y, output_str){
    # - Position the Cursor:
    #   \033[<L>;<C>H
    #      Or
    #   \033[<L>;<C>f
    #   puts the cursor at line L and column C.
    # - Move the cursor up N lines:
    #   \033[<N>A
    # - Move the cursor down N lines:
    #   \033[<N>B
    # - Move the cursor forward N columns:
    #   \033[<N>C
    # - Move the cursor backward N columns:
    #   \033[<N>D

    printf("\033[%d;%df", x, y);

    if ( length(output_str) > 0 ){
        printf("%s", output_str);
    }
}

function clear_to_eol(){
    printf("\033[K");
}

# echo -e "Foo\033[6;12Hbar"
# echo -e "Foo\033[6;12Hbar"

# https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797

# Function to send the cursor to a specific location of the current line.
function go_to_col(dest_col, output_str) {
    printf("\033[%dG", dest_col);

    if ( length(output_str) > 0 ){
        printf("%s",  output_str);
    }
}

# Move the curstor to a specific row
function go_to_row(dest_row, output_str){
    printf("\033[%d;%df", dest_row, 0);

    if ( length(output_str) > 0 ){
        printf("%s",  output_str);
    }
}

function _up(up_n){
    if ( up_n == "" ){
        up_n = 1;
    }

    printf("\033[%dA", up_n);
}

function _down(down_n){
    if ( down_n == "" ){
        down_n = 1;
    }

    printf("\033[%dB", down_n);
}

function _right(right_n){
    if ( right_n == "" ){
        right_n = 1;
    }

    printf("\033[%dC", right_n);
}

function _left(left_n){
    if ( left_n == "" ){
        left_n = 1;
    }

    printf("\033[%dD", left_n);
}

function _rmline(){
    printf("\033[M");
}

function title(title_val){
    printf("\033]0;%s\007", title_val);
}
# Ding the terminal, if enabled
function bell(){
    printf("\007");
}

# Places the timestamp in the very upper right of the screen
function update_timestamp(){
    save_cursor();
    ts = get_timestamp();
    move_cursor(0, terminal_cols() - length(ts));
    printf(ts);
    restore_cursor();
}

# Takes in a percent, and finds the closest key value (after rounding down if needed)
# in the percent_colors array. Returns a color escaped code.
# Examples
#   percent_to_color(0)  == \033[38;5;255m # White
#   percent_to_color(36) == \033[38;5;208m # Orange
#   percent_to_color(50) == \033[38;5;196m # Red
function percent_to_color(percent){
    color = 255;
    
    color_count = asorti(percent_colors, dest, "@val_num_asc");

    for (color_idx = 1; color_idx <= color_count; color_idx++) {
        if ( percent >= dest[color_idx]){
            color = percent_colors[dest[color_idx]];
            break;
        }
    }

    return sprintf("\033[38;5;%dm", color);
}
