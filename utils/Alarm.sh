#!/bin/bash

BASE=$1
SOUND=$BASE
PLAYER=`which audiopreview`
TERMINAL=`which aterm`
VOL=50
#TERMINAL=xterm
# TERMINAL=gnome-terminal

if [[ -z "$PLAYER" || -z "$TERMINAL" ]]; then
    echo "
This script uses audiopreview to play the sound clip and aterm as a terminal

    sudo apt-get install audiopreview aterm

"
    exit
fi


if [[ -f "$BASE.mp3" ]]; then
    SOUND="$BASE.mp3"
elif [[ -f "$BASE.ogg" ]]; then
    SOUND="$BASE.ogg"
fi

# xterm options:
# $TERMINAL -bg orange -fg blue -title "ALARM : Ctrl-C to silence" -e "$PLAYER $SOUND"


$TERMINAL -sb -sr -st  \
        -geometry 50x25+100+100 \
        -borderLess \
        -background orange \
        -foreground blue \
    -backgroundType scale \
  -backgroundPixmap "$BASE.jpg" \
             -title "ALARM : Ctrl-C to silence" \
                 -e $PLAYER --entirely --quiet -l $SOUND \
    2>/dev/null

# I am redirecting STDERR to devnull because I am getting apprently ignorable
# errors: "Error opening file for reading: Permission denied"

killall -9 $PLAYER 2>/dev/null
