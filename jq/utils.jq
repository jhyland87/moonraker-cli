#!/usr/bin/env jq -f

def bbytes:
  def _bbytes(v; u):
    if (u | length) == 1 or (u[0] == "" and v < 10240) or v < 1024 then
      "\(v *100 | round /100) \(u[0])B"
    else
      _bbytes(v/1024; u[1:])
    end;
  _bbytes(.; ":Ki:Mi:Gi:Ti:Pi:Ei:Zi:Yi" / ":");

def bytes:
  def _bytes(v; u):
    if (u | length) == 1 or (u[0] == "" and v < 10000) or v < 1000 then
      "\(v *100 | round /100) \(u[0])B"
    else
      _bytes(v/1000; u[1:])
    end;
  _bytes(.; ":k:M:G:T:P:E:Z:Y" / ":");

# Check if a value is in an array (from stdin)
def in_array(s): 
  . as $in 
  | first(
      if (s == $in) then 
        true 
      else 
        empty 
      end
    ) // false;

# Take a number from stdin, and only get the first n characters
# from it
# 123.4567 | trim_num(2) # 12
# 123.4567 | trim_num(6) # 123.45
def trim_num(len):
  . | tostring | .[0:len] | tonumber;
  
# Calculate standard deviation from an array of numbers (in input).
# If no paramter is passed, then the input data will be interpreted as a 'sample' (𝑠). 
# If population is true, then the input data will be handled as a 'population' (𝜎).
# @see: https://www.calculatorsoup.com/calculators/statistics/standard-deviation-calculator.php#MathJax-Element-19
def calc_std_deviation(population):
  . | 
    (add / length) as $mean | 
    (map(. - $mean | . * .) | add) / (length - (if (population == true) then 0 else 1 end)) | sqrt | trim_num(7);

# Returns the squared value of the standard deviation (calc_std_deviation)
def calc_variance(population):
  . | calc_std_deviation(population) | .*. | trim_num(7);

# Convert a float to an int in string format.
# float_to_int(215.0) == "215"
def float_to_int(num):
  . | num | tonumber | floor | tostring;



def objectArray2CSV:
  . | 
    (if type != "array" 
      then error("root needs to be an array") 
    end) |
    (if (.[0] | type != "object") 
      then error("first array entry is not an object") 
    end) |
    (.[0] | to_entries | map(.key)) as $column_names |
    (if length == 0 
      then halt
    end) |
    ( $column_names | map(ascii_upcase) ),
    (.[] |
      select(type == "object") |
      to_entries |
      [.[] | select(.key| in_array($column_names[]) )] |
      map(.value)
    ) | @tsv;
    #if ($ARGS.named | has("output")) and $ARGS.named["output"] == "tsv" then @tsv else @csv end


