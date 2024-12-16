BEGIN {
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

    max_gradient_color_span = 350;
} 