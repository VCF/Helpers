#!/bin/bash

function usage {
    thisProg="$0"
    echo "
Usage: . $thisProg

These functions are designed to be sourced into startup scripts. For
example, I use these to assure that certain files are opened for
editting, and that some programs are already launched. The functions
will assure that a file/program is not opened if it already is.

"
}

## Properly backgrounding an application launched from a script:
##  https://unix.stackexchange.com/a/305769
## Silencing nohup: appending output to 'nohup.out'
##  https://stackoverflow.com/a/10408906

## Source utility functions
GU="$HOME/generalUtilities"
UTF="$GU/_util_functions.sh"
if [[ -f "$UTF" ]]; then
    . "$UTF"
else
    need=`readlink -f "$GU"`
    echo "
This script expects the 'generalUtilities' repo to be cloned here:
   $need

   https://github.com/maptracker/generalUtilities

"
    exit
fi


function openEmacs {
    ## Open a text file in emacs, if it's not already open
    myFile="$1"
    if [[ -z "$myFile" ]]; then
        msg "$FgRed;$BgYellow" "openEmacs() must provide file as first argument"
        return
    fi
    if [[ ! -f "$myFile" ]]; then
        msg "$FgRed;$BgYellow" "openEmacs() can not find the requested file:"
        msg "$FgYellow;$BgBlue" "  $myFile"
        return
    fi
    bnFile="$(basename "$myFile")"
    chk="$(ps -ef | grep "$bnFile" | grep emacs)"
    if [[ ! -z "$chk" ]]; then
        msg "$FgBlue" "   Already open: $bnFile"
       return
    fi
    nohup emacs "$myFile" >&/dev/null &
    msg "$FgGreen" "         Opened: $myFile"
}

function runProgram {
    ## Launch a program in the background. Will no-op if at least one
    ## instance of the program is already running.
    myExe="$1"
    chkExe="${2:-$myExe}" # Process to check for
    if [[ -z "$myExe" ]]; then
        msg "$FgRed;$BgYellow" "runProgram() must provide file as first argument"
        return
    fi
    chk="$(which "$myExe")"
    if [[ -z "$chk" ]]; then
        msg "$FgRed;$BgYellow" "runProgram() did not find the requested application:"
        msg "$FgYellow;$BgBlue" "  $myExe"
        return
    fi
    chk2="$(ps -ef | grep "$chkExe" | grep -v grep)"
    if [[ ! -z "$chk2" ]]; then
        msg "$FgBlue" "Already running: $chkExe"
        return
    fi
    nohup $myExe >&/dev/null &
    msg "$FgGreen" "        Started: $chkExe"
}

function confirmDir {
    ## Check if a directory is present. Used to confirm NFS mounts are
    ## established. Note that the mount point is always a directory,
    ## so the test should be against a subdirectory.
    chkDir="$1"
    if [[ -z "$chkDir" ]]; then
        msg "$FgRed;$BgYellow" "confirmDir() must provide the path as first argument"
        return
    fi
    if [[ ! -d "$chkDir" ]]; then
        ## Does not look like a directory?
        ## Symlinks to directories <appear> to test properly, but let's
        ## slap a slash on the end to see if that helps
        if [[ -d "$chkDir/" ]]; then
            msg "$FgBlue" "   Directory OK: $chkDir (may be symlink)"
        else
            msg "$FgRed;$BgYellow" " Directory FAIL: $chkDir"
        fi
    fi
    msg "$FgBlue" "   Directory OK: $chkDir"
}

function dashedLine {
    ## Just a visual separator
    msg "$FgCyan" "---------------:---------------------------------"
}

## Taken from my _launcher_functions.sh script
##    https://github.com/VCF/installers/blob/master/games/launchers/_launcher_functions.sh
function countdown {
    sec="$1"
    while [[ "$sec" -gt 0 ]]; do
        printf "Waiting: \e[1;33m%3d\e[0m\r" "$sec"
        ## Bash math: https://unix.stackexchange.com/a/93030
        sec=$(expr "$sec" - 1)
        sleep 1
    done
    echo "                    "
}
