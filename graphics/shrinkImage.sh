#!/bin/bash

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

## Using getopt  vvv #############################################
##   https://stackoverflow.com/a/29754866

LONGOPT=max:,links:,help
OPTIONS=m:l:h
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPT --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi

# read getopt output this way to handle the quoting right:
eval set -- "$PARSED"

d=n f=n v=n outFile=-
# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -m|--max)
            max="$2"
            shift 2
            ;;
        -l|--links)
            chkLink="$2"
            shift 2
            ;;
        -h|--help)
            doHelp=1
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

## Using getopt  ^^^ #############################################

if [[ $# -ne 1 || "$doHelp" ]]; then
    msg "$FgYellow"  "
Shrink Image requires that a file (to be shrunk, if needed) be provided.
It also has the following options:

 -m, --max
     Specify the maximum size of the file. This is used both as a target size
     when shrinking, and as a threshold to see if a file should be shrunk
     Default is 500 - values will be processed as kilobytes

 -l, --links
     Optional path to a folder where symlinks are held. If the shrunk file
     has a different name (because it was converted from a different format
     so has a different suffix) this directory will be scanned to identify
     any symbolic links that need to be renamed. It will only find links
     that have the same name as the target

PNG images will always be refactored to JPG
Other files will be refactored to JPG if their size is over ${max}kb
"
    exit
fi

src="$1"
shrunkFile="$src"

[[ ! "$max" ]] && max=500

if [[ ! "$src" ]]; then
    exit
elif [[ ! -f "$src" ]]; then
    msg "$FgRed" "  [!] Is not a file? $src"
    exit
fi

if [[ "$chkLink" && ! -d "$chkLink" ]]; then
    msg "$FgRed" "[!] Provided symlink directory is not a directory:
  $chkLink

This argument is used if you might have symlinks to the converted file
in question. The script will clean up any broken links that occur
if a file is renamed (eg .png -> .jpg)
"
    exit
fi

srcBase="$(basename "$src")"
srcDir="$(dirname "$src")"
srcPfx="$(echo "$srcBase" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]')"
srcSz=$(ls -1s "$src" | sed 's/ .*//')

if [[ "$srcPfx" == "png" ]]; then
    msg "$FgBlue" "  Converting ${srcSz}kb $srcPfx to jpg"
elif (( $srcSz > $max )); then
    msg "$FgBlue" "  Reducing ${srcSz}kb to ${max}kb"
else
    exit
fi

## Assure output file will be JPG:
outBase="$(echo "$srcBase" | sed 's/\.[a-z]*$/.jpg/I')"
## We will write to a temporary file:
tmpOut="$srcDir/TMP-$outBase"

convert "$src" \
        -define jpeg:extent=${max}kb \
        "$tmpOut"

if [[ ! -f "$tmpOut" ]]; then
    msg "$FgRed" "  [!] Did not find converted file!"
    exit
fi

newSz=$(ls -1s "$tmpOut" | sed 's/ .*//')
if (( $newSz > $srcSz )); then
    msg "$FgYellow" "  Conversion did not help - discarding ${newSz}kb file"
    rm "$tmpOut"
    exit
fi

# Remove original file and rename new one
newName="$srcDir/$outBase"
rm "$src"
mv "$tmpOut" "$newName"

shrunkFile="$newName"

msg "$FgBlue;$BgYellow" "  [+] ${newSz}kb $newName"
if [[ "$chkLink" && $srcBase != $outBase ]]; then
    ## File was renamed and there's a request to relink, if needed
    found="$(find "$chkLink" -name "$srcBase" -type l)"

    ## TODO - handle multiple hits
    ## TODO - match against target, not symlink name
    
    if [[ "$found" ]]; then
        ## There is, in fact, a symlink to the old file
        ## Get the link as defined, in case it's relative
        lnkTrg="$(readlink "$found")"
        newLnk="$(dirname "$lnkTrg")/$outBase"
        lnkSrc="$(dirname "$found")/$outBase"
        rm "$found"
        ln -s "$newLnk" "$lnkSrc"
        msg "$FgCyan" "    Link Updated: $lnkSrc"
    fi
fi

