#!/bin/bash

## A terminal-based timer, because I'm not really happy with the
## kitchen timers I have.

my_dir="$(dirname "$0")"

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

ALARMEXE="$my_dir/Alarm.sh"

TIME=$1
START=`date +%s`

if [ -z "$TIME" ]; then
    msg 36 "
Enter the number of seconds you wish to time
"
    exit;
fi

if [[ `echo "$TIME" | egrep -i '(m|min)'` ]]; then
    ## Request is in minutes
    TIME=`echo "$TIME" | sed -E 's/ *(min|m)//'`
    TIME=$((60 * TIME))
fi

END=$((START + TIME))

# Floating point math:
# http://www.linuxjournal.com/content/floating-point-math-bash

printf '\e[34;43m%-6s\e[m' "This is text"

NOW=$(date +%s)

while [ $NOW -lt $END ]
do
    NOW=$(date +%s)
    # How much time is left?
    REMAIN=$((END - NOW))
    # Because bash can not handle floating points, we will calculate
    # the fraction remaining as an integer percentage and test that:
    PERC=$(echo "scale=0; 100 * $REMAIN / $TIME" | bc)
    let BLINK=$REMAIN%2
    BLINKCOL="34;43"
    if [ $BLINK -eq 1 ]; then
        BLINKCOL="33;44"
    fi
    PERCCOL="32";
    if [ $PERC -le 10 ]; then
        # Color time red when down to 10%
        PERCCOL="31"
    elif [ $PERC -le 20 ]; then
        # Color time yellow when down to 20%
        PERCCOL="33"
    fi
    FMT='\r\e['$BLINKCOL'mSeconds remaining\e[m: \e['$PERCCOL'm%6d\e[m'
    printf "$FMT" $REMAIN
    sleep 1
done
printf "\r\e[41;33;1mCountdown Complete\e[m $TIME seconds elapsed. \e[34mHit Ctrl-c to cancel\e[m\n"

$ALARMEXE "$my_dir/Beep_example"


