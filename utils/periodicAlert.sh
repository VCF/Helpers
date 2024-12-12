#!/bin/bash

ABOUT="
This script is designed to repeatedly play an audio file from the command line.
Used for periodic reminders
"
my_dir="$(dirname "$0")"

. "$my_dir/timeFunctions.sh"

CF="$my_dir/../../confFiles"
UTF="$CF/systemSetup/_util_functions.sh"
if [[ -f "$UTF" ]]; then
    . "$UTF"
else
    need=`readlink -f "$CF"`
    echo "
This script expects the 'confFiles' repo to be cloned here:
   $need

   https://github.com/maptracker/confFiles

"
    exit
fi

pexe="gst123"
exe="$(which "$pexe")"

TREQ="$1"
REPS="${2:-999999999}"
SOUND="${3:-$my_dir/ding.ogg}"
EVENT=`date +%s`
START=$EVENT

if [ -z "$TREQ" ]; then
    msg 36 "
Enter the time interval you wish to alert on

"
    exit;
fi

TIME="$(requestToSeconds "$TREQ")"

[[ -z "$TIME" ]] && exit

printf '\e[34;43m%-6s\e[m' "This is text"
PERCCOL="32";

DONE=0
while (( $DONE < $REPS ))
do
    ## We have more repetitiions to perform
    NOW=$(date +%s)
    ## What is the future time we should wait for?
    EVENT=$(( $EVENT + $TIME ))
    until [ $NOW -lt $EVENT ]
    do
        ## We calculate this in a loop - because I learned the hard
        ## way if you sleep the system while the timer is running, it
        ## will play the alert each time until the current time is
        ## reached, and this prevents login, at least in Ubuntu.
        EVENT=$(( $EVENT + $TIME ))
        DONE=$(( $DONE + 1 ))
    done

    ## Alright, now we have the next most-proximal event in the future
    ## Count down until we reach it
    while [ $NOW -lt $EVENT ]
    do
        NOW=$(date +%s)
        # How much time is left?
        REMAIN=$((EVENT - NOW))
        let BLINK=$REMAIN%2
        BLINKCOL="34;43"
        if [ $BLINK -eq 1 ]; then
            BLINKCOL="33;44"
        fi
        FMT='\r\e[0K\e['$BLINKCOL'mRemaining\e[m: \e['$PERCCOL'm%s\e[m'
        printf "$FMT" "$(secondsToNiceTime "$REMAIN")"
    
        ## We have not run out the current timer
        sleep 1
    done
    DONE=$(( $DONE + 1 ))
    # Clear line https://en.wikipedia.org/wiki/ANSI_escape_code
    printf "\r\e[0K" 
    ELAPSE=$(( $NOW - $START ))
    echo "#${DONE} - $(secondsToNiceTime "$ELAPSE")"
    PLAYIT="$($exe "$SOUND")"
done
