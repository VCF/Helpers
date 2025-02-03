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
warn  () { msg "$BgYellow;$FgRed" "$1"; }
error () { msg "$BgRed;$FgYellow" "$1"; }
info  () { msg "$BgBlue;$FgWhite" "$1"; }
note  () { msg "$FgBlue" "$1"; }


function grepPattern {
    PAT="$1"
    TXT="$2"
    if [[ "$PAT" == "" ]]; then
        warn "grepPattern() requires the pattern to be passed as first argument"
        exit
    fi
    echo $(echo "$TXT" | egrep -o "$PAT")
}

function fileTypeRigorous {
    ## Use `file` to assess contents of the downloaded file
    path="$1"
    chk=$(file "$path" | sed 's/^.*://')
    if [[ $(grepPattern "JPEG image" "$path") != "" ]]; then
        echo "jpg"
    elif [[ $(grepPattern "Web.P image" "$path") != "" ]]; then
        echo "webp"
    elif [[ $(grepPattern "PNG image" "$path") != "" ]]; then
        echo "png"
    elif [[ $(grepPattern "GIF image" "$path") != "" ]]; then
        echo "gif"
    elif [[ $(grepPattern "ASCII text" "$path") != "" ]]; then
        echo "txt"
        ## Does not get nuance, like .md or .js !!
    elif [[ $(grepPattern "MP4 Base Media" "$path") != "" ]]; then
        echo "mp4"
    elif [[ $(grepPattern "PDF document," "$path") != "" ]]; then
        echo "pdf"
    elif [[ $(grepPattern "Zip archive" "$path") != "" ]]; then
        echo "zip"
    elif [[ $(grepPattern "EPUB document" "$path") != "" ]]; then
        echo "epub"
    elif [[ $(grepPattern "WebM" "$path") != "" ]]; then
        echo "webm"
    elif [[ $(grepPattern "OpenDocument Presentation" "$path") != "" ]]; then
        echo "odp"
    elif [[ $(grepPattern "OpenDocument Spreadsheet" "$path") != "" ]]; then
        echo "ods"
    elif [[ $(grepPattern "Debian binary package" "$path") != "" ]]; then
        echo "deb"
    elif [[ $(grepPattern "Apple Driver Map" "$path") != "" ]]; then
        echo "dmg"
    elif [[ $(grepPattern "FooBar" "$path") != "" ]]; then
        echo "foo"
    elif [[ $(grepPattern "FooBar" "$path") != "" ]]; then
        echo "foo"
    elif [[ $(grepPattern "FooBar" "$path") != "" ]]; then
        echo "foo"
    elif [[ $(grepPattern "FooBar" "$path") != "" ]]; then
        echo "foo"
    elif [[ $(grepPattern "FooBar" "$path") != "" ]]; then
        echo "foo"
    else
        echo "unk"
        warn "Unknown file type for: $path
$chk"
    fi
}

