#!/bin/bash

ABOUT="
The functions in this script are designed to be used by other scripts to manage
human-friendly time designations
"

function requestToSeconds {
    REQ="$1"

    if [[ -z "$REQ" ]]; then
        >&2 echo "[ERR] requestToSeconds requires a number or string as input"
        echo ""
        return
    fi

    # Extract the numeric component
    NUM="$(echo "$REQ" | egrep -o '([0-9]+|[0-9]*\.[0-9]*)')"
    if [[ -z "$NUM" ]]; then
        >&2 echo "[ERR] requestToSeconds requires a numeric component, not '$REQ'"
        echo ""
        return
    fi

    # Extract any non-numeric component, to lowercase
    NN="$(echo "$REQ" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z]*//g')"

    if [[ -z $NN || "$(echo "$NN" | egrep '^(s|sec|seconds?)$')" != "" ]]; then
        # Seconds
        echo "$NUM"
    elif [[ "$(echo "$NN" | egrep '^(m|mins?|minutes?)$')" != "" ]]; then
        # Minutes
        echo $(($NUM * 60))
    elif [[ "$(echo "$NN" | egrep '^(h|hr|hours?)$')" != "" ]]; then
        # Hours
        echo $(($NUM * 60 * 60))
    elif [[ "$(echo "$NN" | egrep '^(d|days?)$')" != "" ]]; then
        # Days
        echo $(($NUM * 60 * 60 * 24))
    else
        >&2 echo "[ERR] requestToSeconds did not recognize unit '$NN'
Supported units (case-insensitive):
  s, sec, second, seconds
  m, min, minute, minutes
  h, hr, hour, hours
  d, day, days
"
        echo ""
    fi
}

function secondsToNiceTime {
    REQ="$1"

    # Clean leading/trailing whitespace
    REQ="$(echo "$REQ" | sed 's/^\s+//' | sed 's/\s+$//')"
    if [[ -z "$REQ" ]]; then
        >&2 echo "[ERR] secondsToNiceTime requires a number as input"
        echo ""
        return
    fi

    if [[ -z "$(echo "$REQ" | egrep -o '([0-9]+|[0-9]*\.[0-9]*)')" ]]; then
        >&2 echo "[ERR] secondsToNiceTime did not recognize '$REQ' as a number"
        echo ""
        return
    fi

    DY=86400
    HR=3600
    MN=60
    RV="" # Our return value
    if (( $REQ >= $DY )); then
        # We have at least one day
        DAYS=$(($REQ/$DY))
        [[ $RV == "" ]] || RV="$RV " # pad exising value with space
        RV="${RV}$DAYS day"
        REQ=$(($REQ - $DAYS * $DY))    # Recover unused seconds
    fi
    if (( $REQ >= $HR )); then
        # We have at least one hour
        HRS=$(($REQ/$HR))
        [[ $RV == "" ]] || RV="$RV " # pad exising value with space
        RV="${RV}$HRS hr"
        REQ=$(($REQ - $HRS * $HR))    # Recover unused seconds
    fi
    if (( $REQ >= $MN )); then
        # We have at least one minute
        MINS=$(($REQ/$MN))
        [[ $RV == "" ]] || RV="$RV " # pad exising value with space
        RV="${RV}$MINS min"
        REQ=$(($REQ - $MINS * $MN))    # Recover unused seconds
    fi
    if [[ $REQ != "" && $REQ -gt 0 ]]; then
        # Add remaining seconds
        [[ $RV == "" ]] || RV="$RV " # pad exising value with space
        RV="${RV}$REQ sec"
    fi
    echo "$RV"
}
