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
        msg "$FgRed;$BgYellow" "  $myFile"
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
        return
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

function start_ssh_agent {
    ## https://stackoverflow.com/a/48509425
    ssh-add -l &>/dev/null
    if [ "$?" == 2 ]; then
        # Could not open a connection to your authentication agent.

        # Load stored agent connection info.
        test -r ~/.ssh-agent && \
            eval "$(<~/.ssh-agent)" >/dev/null

        ssh-add -l &>/dev/null
        if [ "$?" == 2 ]; then
            # Start agent and store agent connection info.
            (umask 066; ssh-agent > ~/.ssh-agent)
            eval "$(<~/.ssh-agent)" >/dev/null
            msg "$FgGreen" "      SSH Agent: Started PID $SSH_AGENT_PID"
        else
            msg "$FgBlue" "      SSH Agent: Loaded from ~/.ssh_agent"
        fi
    elif [[ -z "$SSH_AGENT_NOTED" ]]; then
        msg "$FgBlue" "      SSH Agent: Running"
    fi
    SSH_AGENT_NOTED="1"
}

function add_ssh_key {
    path="$1"
    if [[ ! -s "$path" ]]; then
        msg "$FgRed;$BgYellow" "No such SSH Key: $path"
        return
    fi

    start_ssh_agent
    chk=$(ssh-add -l | grep -F "$path")
    if [[ -z "$chk" ]]; then
        msg "$FgMagenta" "SSH Key Request: $path"
        ssh-add "$path"
    else
        msg "$FgBlue" "  SSH Key Ready: $path"
     fi
}
