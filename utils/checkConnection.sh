#!/bin/bash

## Command line script to compactly show external internet
## connectivity, using ANSI color markup for visibility. Idea is to
## keep a terminal off to the side with clearly visible color tokens
## to easily monitor if connection goes down/up


## Hammer Comcast's domain rather than, say, Google's, since Comcast
## is the reason I needed to make this script ...
HOST="www.xfinity.com"
WAIT=5

echo -e "Monitoring connection status using: \e[35m $HOST \e[m"

GoodFmt='\r\e[42;37m [+] \e[m %s Good connection'
NoHostFmt='\r\e[41;33m /!\\ \e[m %s DNS not accessible'
UnkFmt='\r\e[45;37m (?) \e[m %s Unrecognized response'

while [[ 1 == 1 ]]
do
    ## -c 1 = Just try one connection
    PING=$(ping -c 1 "$HOST" 2>&1 )
    FMT="$UnkFmt"
    if [[ $(echo "$PING" | grep 'Name or service not known') != "" ]]; then
        ## DNS failure, usually means total connectivity failure
        FMT="$NoHostFmt"
    else
        Time=$(echo "$PING" | egrep -o 'time=[0-9\.]* ms')
        if [[ "$Time" != "" ]]; then
            ## If we're seeing a time, then we can connect
            clean=$(echo "$Time" | sed s/time=//)
            FMT="$GoodFmt : \e[44;33m $clean \e[m"
            ## TODO
            ## Detect "Connected, but slow"
        else
            ## Unrecognized response from ping
            FMT="$UnkFmt : $PING"
        fi
    fi
    ## Report status and current time
    printf "$FMT" "$(date +'%H:%M:%S')"
    sleep "$WAIT"
done
