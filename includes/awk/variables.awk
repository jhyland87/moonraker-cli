BEGIN {

    # Values that will be used for positive mesh value mappings
    positive_colors[0]="243;255;215";
    positive_colors[1]="255;251;185";
    positive_colors[2]="254;247;181";
    positive_colors[3]="254;243;177";
    positive_colors[4]="254;239;173";
    positive_colors[5]="254;235;170";
    positive_colors[6]="253;231;166";
    positive_colors[7]="253;227;162";
    positive_colors[8]="253;223;158";
    positive_colors[9]="253;219;155";
    positive_colors[10]="253;215;151";
    positive_colors[11]="252;211;147";
    positive_colors[12]="252;207;143";
    positive_colors[13]="252;203;140";
    positive_colors[14]="252;199;136";
    positive_colors[15]="251;195;132";
    positive_colors[16]="251;191;128";
    positive_colors[17]="251;187;125";
    positive_colors[18]="251;183;121";
    positive_colors[19]="251;179;117";
    positive_colors[20]="250;175;113";
    positive_colors[21]="250;171;110";
    positive_colors[22]="250;167;106";
    positive_colors[23]="250;163;102";
    positive_colors[24]="249;159;98";
    positive_colors[25]="249;155;95";
    positive_colors[26]="249;151;91";
    positive_colors[27]="249;147;87";
    positive_colors[28]="249;143;84";
    positive_colors[29]="247;140;83";
    positive_colors[30]="244;136;81";
    positive_colors[31]="242;132;80";
    positive_colors[32]="240;128;79";
    positive_colors[33]="237;124;77";
    positive_colors[34]="235;120;76";
    positive_colors[35]="233;116;75";
    positive_colors[36]="230;112;74";
    positive_colors[37]="228;108;72";
    positive_colors[38]="226;104;71";
    positive_colors[39]="223;100;70";
    positive_colors[40]="221;96;68";
    positive_colors[41]="219;92;67";
    positive_colors[42]="216;88;66";
    positive_colors[43]="214;84;65";
    positive_colors[44]="211;80;63";
    positive_colors[45]="209;76;62";
    positive_colors[46]="207;72;61";
    positive_colors[47]="204;68;59";
    positive_colors[48]="202;64;58";
    positive_colors[49]="200;60;57";
    positive_colors[50]="197;56;56";
    positive_colors[51]="195;52;54";
    positive_colors[52]="193;48;53";
    positive_colors[53]="190;44;52";
    positive_colors[54]="188;40;50";
    positive_colors[55]="186;36;49";
    positive_colors[56]="183;32;48";
    positive_colors[57]="181;28;47";
    positive_colors[58]="179;24;45";
    positive_colors[59]="176;20;44";

    # Values that will be used for negative mesh value mappings
    negative_colors[0]="255;251;185"; 
    negative_colors[1]="252;250;189";
    negative_colors[2]="249;249;193";
    negative_colors[3]="246;248;197";
    negative_colors[4]="243;247;201";
    negative_colors[5]="240;246;205";
    negative_colors[6]="237;245;209";
    negative_colors[7]="234;244;213";
    negative_colors[8]="231;243;217";
    negative_colors[9]="228;242;221";
    negative_colors[10]="225;241;225";
    negative_colors[11]="222;240;229";
    negative_colors[12]="219;239;233";
    negative_colors[13]="216;238;237";
    negative_colors[14]="213;237;241";
    negative_colors[15]="210;236;244";
    negative_colors[16]="207;232;242";
    negative_colors[17]="203;228;240";
    negative_colors[18]="200;224;238";
    negative_colors[19]="196;220;236";
    negative_colors[20]="193;216;234";
    negative_colors[21]="189;212;232";
    negative_colors[22]="186;208;230";
    negative_colors[23]="182;204;228";
    negative_colors[24]="179;200;226";
    negative_colors[25]="175;196;224";
    negative_colors[26]="172;192;222";
    negative_colors[27]="168;188;220";
    negative_colors[28]="164;184;218";
    negative_colors[29]="161;180;216";
    negative_colors[30]="157;176;214";
    negative_colors[31]="154;172;211";
    negative_colors[32]="150;168;209";
    negative_colors[33]="147;164;207";
    negative_colors[34]="143;160;205";
    negative_colors[35]="140;156;203";
    negative_colors[36]="136;152;201";
    negative_colors[37]="133;148;199";
    negative_colors[38]="129;144;197";
    negative_colors[39]="126;140;195";
    negative_colors[40]="122;136;193";
    negative_colors[41]="118;132;191";
    negative_colors[42]="115;128;189";
    negative_colors[43]="111;124;187";
    negative_colors[44]="108;120;185";
    negative_colors[45]="104;116;183";
    negative_colors[46]="101;112;180";
    negative_colors[47]="97;108;178";
    negative_colors[48]="94;104;176";
    negative_colors[49]="90;100;174";
    negative_colors[50]="87;96;172";
    negative_colors[51]="83;92;170";
    negative_colors[52]="80;88;168";
    negative_colors[53]="76;84;166";
    negative_colors[54]="72;80;164";
    negative_colors[55]="69;76;162";
    negative_colors[56]="65;72;160";
    negative_colors[57]="62;68;158";
    negative_colors[58]="58;64;156";
    negative_colors[59]="55;60;154";

    colors["coordinates"] = "\033[38;2;37;1m";
    colors["xy"] = "\033[38;5;242m";

    # Where to start the grid - The numbers will show before this.
    grid_start_indent = 3;

    char_set["superset"]="⁰¹²³⁴⁵⁶⁷⁸⁹⁻⁺᠂⁼⁽⁾ˡˢˣʰᵐᵒⁱʲʳʷʸᵍ";
    char_set["subset"]="₀₁₂₃₄₅₆₇₈₉₋₊․₌₍₎ₗₛₓₕₘₒᵢjrwyg";
    #ₒₓₕₖₘₙₚₜ
    char_set["normal"]="0123456789-+.=()lsxhmoijrwyg";

    block["upper"] = "\u2580"; # ▀
    block["lower"] = "\u2584"; # ▄ 
    block["full"]  = "\u2588"; # █

    # upper_half_block="\u2580" # ▀
    # lower_half_block="\u2584" # ▄  
    # full_block="\u2588\u2588" # █

    coordinates["up"] = "\u2B06"; # ⬆
    coordinates["down"] = "\u2B07"; # ⬇
    coordinates["left"] = "\u2B05"; # ⬅
    coordinates["right"] = "\u2B95"; # ⮕
    coordinates["X"] = "\uFF38";
    coordinates["Y"] = "\uFF39";

    max_gradient_color_span = 600;
} 