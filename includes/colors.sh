#!/usr/bin/env bash

# Set fg color with \e[38;5;${COLOR}m:
# echo -e '\e[38;5;17mTest\e[0m'
# echo -e '\e[38;5;226mYellow text\e[0m'

# Set bg color with \e[48;5;${COLOR}m:
# echo -e '\e[48;5;17mBlue background\e[0m'

# Change the fg and bg colors:
# echo -e '\e[48;5;226m\e[38;5;234mDark text on yellow fg\e[0m'

# Execute the function "showcolors" (defined in ~/.bash_functions) to see 
# a list of all possible colors, as well as their color codes

# https://github.com/chalk/ansi-styles/blob/main/index.js#L9-L64

# Just some variables for some common colors


# This resets everything (colors and styles)
_none_="\e[0m"

_red_="\e[31m"
_green_="\e[32m"
_yellow_="\e[33m"
_blue_="\e[34m"
_pink_="\e[35m"
_cyan_="\e[36m"
_grey_="\e[37m"
_orange_="\e[38;5;214m"
_olivedrab_="\e[38;5;64m"
_olive_="\e[38;5;58m"
_dirtyyellow_="\e[38;5;142m"

_nocolor_="\e[39m"

_bold_="\e[1m"
_nobold_="\e[22m"
_bold_="\e[1m"
_nobold_="\e[22m"

_dim_="\e[2m"
_nodim_="\e[22m"
_xdim_="\e[22m"

_italic_="\e[3m"
_noitalic_="\e[23m"

_underline_="\e[4m"
_nounderline_="\e[24m"

_overline_="\e[53m"
_nooverline_="\e[55m"

_inverse_="\e[7m"
_xinverse_="\e[27m"


_hide_="\e[8m"
_xhide_="\e[28m"

_strike_="\e[9m"
_xstrike_="\e[29m"


_xcolr_="\e[39m"

# Shorter aliases
_grn_=${_green_}
_yel_=${_yellow_}
_blu_=${_blue_}

_pnk_=${_pink_}
_cyn_=${_cyan_}
_gry_=${_grey_}
_ora_=${_orange_}
_odg_=${_olivedrab_}
_olv_=${_olive_}
_dyel_=${_dirtyyellow_}


_bld_=${_bold_}
_xbld_=${_nobold_}

_ital_=${_italic_}
_xital_=${_noitalic_}

_undl_=${_underline_}
_xundl_=${_nounderline_}

_strk_=${_strike_}
_xstrk_=${_nostrike_}

function _boldn {
    printf "%b%s" "${_bold_}" "${*}" "${_nobold_} \n"
}

function _boldred {
    printf "%b%s" "${_bold_}${_red_}" "${*}" "${_none_}${_nobold_} \n"
}

function _boldyellow {
    printf "%b%s" "${_bold_}${_dyel_}" "${*}" "${_none_}${_nobold_} \n"
}

function _dimn {
    echo -en "\e[2m${*}\e[0m"
}
function _italn {
    echo -en "\e[3m${*}\e[0m"
    printf "%b%s" "${_ital_}" "${*}" "${_nital_} \n"
}
function _uscoren { # Underscore 
    echo -en "\e[4m${*}\e[0m"
}
function _hln { # highlight (reverse bg/fg)
    echo -en "\e[7m${*}\e[0m"
}


function _redn {
    echo -en "${_red_}${*}${_none_}"
}
function _greenn {
    echo -en "\e[1;32m${*}\e[0m"
}
function _yellown {
    echo -en "\e[1;33m${*}\e[0m"
}
function _whiten {
    echo -en "\e[1;37m${*}\e[0m"
}
function _greyn {
    echo -en "\e[2;37m${*}\e[0m"
}


function _bold {
    _boldn "${*}"
    echo
}
function _red {
    #echo -e "\e[1;31m${*}\e[0m"
    _redn "${*}"
    echo
}

function _green {
    #echo -e "\e[1;32m${*}\e[0m"
    _greenn "${*}"
    echo
}

function _yellow {
    #echo -e "\e[1;33m${*}\e[0m"
    _yellown "${*}"
    echo
}
function _white {
    #echo -e "\e[1;37m${*}\e[0m"
    _whiten "${*}"
    echo
}
function _grey {
    #echo -e "\e[2;37m${*}\e[0m"
    _greyn "${*}"
    echo
}

function showcolors {
    #curl -s https://gist.githubusercontent.com/HaleTom/89ffe32783f89f403bba96bd7bcd1263/raw/e50a28ec54188d2413518788de6c6367ffcea4f7/print256colours.sh | bash

    ~/Documents/scripts/bash/print256colours.sh
}

function _colors {
    _red "This is _red"
    _green "This is _green"
    _yellow "This is _yellow"
    _white "This is _white"
    _grey "This is _grey"

    printf "Only red is %s when using _redn\n" "$(_redn red)"
}

function decolor { 
	cat - | sed 's/'"$(printf '\x1b')"'\[[^@-~]*[@-~]//g'
}


declare -xg  	_none _red _green _yellow _blue _pink _cyan _grey _orange _olivedrab _olive \
							_dirtyyellow _nocolor _bold _nobold _bold _nobold _dim _nodim _xdim _italic \
							_noitalic _underline _nounderline _overline _nooverline _inverse _xinverse \
							_hide _xhide _strike _xstrike _xcolr _grn _yel _blu _pnk _cyn _gry _ora _odg \
							_olv _dyel _bld _xbld _ital _xital _undl _xundl _strk _xstrk  \
							_boldn _boldred _boldyellow _dimn _italn _uscoren _hln _redn _greenn _yellown \
							_whiten _greyn _bold _red _green _yellow _white _grey showcolors _colors decolor