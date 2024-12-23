BEGIN {
    #CONVFMT = "%2.7f"
    colors["coordinates"] = "\033[38;2;37;1m";
    colors["xy"] = "\033[38;5;242m";

    # Where to start the grid - The numbers will show before this.
    grid_start_indent = 3;

    char_set["superset"] = "⁰¹²³⁴⁵⁶⁷⁸⁹⁻⁺᠂⁼⁽⁾﹪ˡˢˣʰᵐᵒⁱʲʳʷʸᵍ";
    char_set["subset"] = "₀₁₂₃₄₅₆₇₈₉₋₊․₌₍₎﹪ₗₛₓₕₘₒᵢjrwyg";
    #ₒₓₕₖₘₙₚₜ
    char_set["normal"] = "0123456789-+.=()%lsxhmoijrwyg";

    # ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏ
    # ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘꞯʀꜱᴛᴜᴠᴡXʏᴢ
    # ﹕﹖﹗﹘﹙﹚﹛﹜﹟﹠﹡﹢﹣﹤﹥﹦﹨﹩﹪﹫
    #ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘꞯʀꜱᴛᴜᴠᴡʏᴢ﹕﹖﹗﹙﹚﹛﹜﹟﹠﹡﹢﹣﹤﹥﹦﹨﹩﹪﹫
    # ᵃᵇᶤᶥ
    char_set["sm_normal"] = "ABCDEFGHIJKLMNOPQRSTUVWYZabcdefghijklmnoqrstuvwxyz0123456789:?!(){}#&*+-<>=\\$%@";
    char_set["small"] = "ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘꞯʀꜱᴛᴜᴠᴡʏᴢᵃᵇᶜᵈᵉᶠᵍʰᶥʲᵏᶩᵐᶮᵒᵖʳˢᵗᵘᵛʷˣʸᶻ₀₁₂₃₄₅₆₇₈₉﹕﹖﹗₍₎﹛﹜﹟﹠﹡﹢﹣﹤﹥﹦﹨﹩﹪﹫";

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

    percent_colors[5] = 255;
    percent_colors[10] = 230;
    percent_colors[15] = 229;
    percent_colors[20] = 227;
    percent_colors[25] = 226;
    percent_colors[30] = 220;
    percent_colors[35] = 214;
    percent_colors[40] = 208;
    percent_colors[35] = 166;
    percent_colors[50] = 124;
    percent_colors[55] = 160;
    percent_colors[100] = 196;

    bar_graph_chars[0] = "⠀⠀";
    bar_graph_chars[1] = "⣀⡀";
    bar_graph_chars[2] = "⣤⡄";
    bar_graph_chars[3] = "⣶⡆";
    bar_graph_chars[4] = "⣶⡆";
    bar_graph_chars[5] = "⣿⡇";
} 