#!/bin/bash

## Collection of re-used utility functions

FgBlack="30"
FgRed="31"
FgGreen="32"
FgYellow="33"
FgBlue="34"
FgMagenta="35"
FgCyan="36"
FgWhite="37"
BgBlack="40"
BgRed="41"
BgGreen="42"
BgYellow="43"
BgBlue="44"
BgMagenta="45"
BgCyan="46"
BgWhite="47"

function msg {
    ## Colorized terminal message.
    COL=$1 # The ANSI color code(s)
    MSG=$2 # The text to print
    [[ -z "$COL" ]] && col="32"
    >&2 echo -e "\033[1;${COL}m${MSG}\033[0m";
}

## Just some pre-fommated msg commands
warn()  { msg "$BgYellow;$FgRed" "$1" }
error() { msg "$BgRed;$FgYellow" "$1" }
info()  { msg "$BgBlue;$FgWhite" "$1" }
note()  { msg "$FgBlue" "$1" }


function grepPattern {
    PAT="$1"
    TXT="$2"
    if [[ "$PAT" == "" ]]; then
        warn "grepPattern() requires the pattern to be passed as first argument"
        exit
    fi
    echo $(echo "$TXT" | egrep -o "$PAT")
}
