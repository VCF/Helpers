#!/bin/bash

ABOUT="
Tracking the tools Linux uses to play sound files from the command line
has become tedious. This basic script just centralizes the current
utility that's working in the most recent versions of Mint

Prior tools that don't work now:
  AudioPreview    failed in Tricia
  gst123          failed in Wilma

"

## play (via sox) suggested in https://askubuntu.com/a/920542
# The executable we'll use
psExe="play"
# The package it resides in
psPack="sox"

# Can we locate it?
psWhc="$(which $psExe)"
if [ -z "$psWhc" ]; then
    # Nope, can't find it
        echo -e "
[ERR] playSound uses $psExe to play the sound clip

    sudo apt-get install $psPack
"
fi

function playSound {
    SOUND="$1" # The audio file we will play
    OPTS="$2"  # Optional options to pass to the player
    if [ -z "$psWhc" ]; then
        # Tool not available
        # We already gave feedback when we sourced this file, just return
        return
    elif [ -z "$SOUND" ]; then
        echo "[ERR] playSound must be provided a path to a sound file"
        return
    elif [ ! -s "$SOUND" ]; then
        echo -e "[ERR] playSound could not find the requested sound file:
  $SOUND"
        return
    fi
    PSE="$($psWhc -q "$SOUND" $OPTS 2>/dev/null)"
}
