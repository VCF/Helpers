#!/bin/bash

ABOUT="
This script is designed to play an audio file from the command line.
Used for timers
"

BASE=$1

if [[ ! "$BASE" ]]; then
    echo "
This script expects a 'base' file path as the first and only argument.
If you provide 'my_sound', it will then expect two files:
  my_sound.mp3
  my_sound.jpg
The sound file will be played repeatedly for the alarm
The terminal playing the sound will have the JPEG as the backgroud
Alternatively you can provide an OGG file rather than an MP3:
  my_sound.ogg
"
fi


SOUND=$BASE
## AudioPreview no longer in Tricia
pexe="gst123"
# PLAYER=`which audiopreview`
PLAYER=`which $pexe`
TERMINAL=`which aterm`
VOL=50
#TERMINAL=xterm
# TERMINAL=gnome-terminal

if [[ -z "$PLAYER" ]]; then
    echo "
This script uses $pexe to play the sound clip

    sudo apt-get install $pexe

"
    exit
fi

if [[ -z "$TERMINAL" ]]; then
    echo "
This script uses aterm as a terminal

    sudo apt-get install aterm

"
    exit
fi


if [[ -f "$BASE.mp3" ]]; then
    SOUND="$BASE.mp3"
elif [[ -f "$BASE.ogg" ]]; then
    SOUND="$BASE.ogg"
else
    echo "Failed to find either of these files:
  $BASE.mp3
  $BASE.ogg
"
    exit
fi

# xterm options:
# $TERMINAL -bg orange -fg blue -title "ALARM : Ctrl-C to silence" -e "$PLAYER $SOUND"

PROMPT="ALARM : Ctrl-C to silence"

$TERMINAL -sb -sr -st  \
          -geometry 50x25+100+100 \
        -background orange \
        -foreground blue \
    -backgroundType scale \
  -backgroundPixmap "$BASE.jpg" \
             -title "$PROMPT" \
                 -e $PLAYER --repeat --quiet $SOUND \
    2>/dev/null

# I am redirecting STDERR to devnull because I am getting apprently ignorable
# errors: "Error opening file for reading: Permission denied"

killall -9 $PLAYER 2>/dev/null
