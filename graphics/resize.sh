#!//usr/bin/env bash

## Resize the primary monitor to maximum resolution

## Get the identifier for the primary monitor

monID="$(xrandr --query | grep "connected primary" | sed 's/ .*//')"

if [[ -z "$monID" ]]; then
    echo "Failed to find primary monitor identifier"
    exit
fi

## Allow resolution to be specified as first argument

maxRes="$1"

if [[ -z "$maxRes" ]]; then
    ## No resolution provided, figure out the max:
    maxRes="$(xrandr --query | egrep -A1 "^$monID" | tail -n1 | sed 's/^ *//' | sed 's/ .*//')"

    if [[ -z "$maxRes" ]]; then
        echo "Failed to determine maximum resolution for $monID"
        exit
    fi
fi


echo "Setting resolution on $monID to $maxRes ... "

xrandr --output "$monID" --mode "$maxRes"

echo "  Done."
