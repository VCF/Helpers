#!/bin/bash

## Scans a single image from a flatbed scanner, assigns a date-stamped
## name, stores in a folder for later editting / renaming

HELP='
## Debugging / Checking
scanimage -L
sudo sane-find-scanner

## Needs package:
   sudo apt-get install xsltproc
   sudo apt-get install sane sane-utils xsane
## Needs drivers installed: 
   export pkgLoc="/abyss/Installers/Linux/Linux Drivers/Epson Scanner/Mint22"

   But maybe not iscan? Maybe Epson2?

   cd "$pkgLoc/iscan*.deb"
   ./install.sh


## Will need to:
  sudo emacs /etc/sane.d/epkowa.conf
## and add:
usb 0x04b8 0x0131




## Stuff below probably not relevant

## May need to update USB rules
https://askubuntu.com/a/974626

## INSTALLER IS BROKEN

This was only a problem with iscan

Due to a change of "libsane" to "libsane1" in the repository.
Follow instructions to rebuild DEB file:

  https://askubuntu.com/a/1527529

## OLDER INSTRUCTIONS
   sudo dpkg -i "$pkgLoc/iscan-data_1.26.0-1_all.deb"
   sudo dpkg -i "$pkgLoc/iscan_2.29.3-1~usb0.1.ltdl7_amd64.deb"

https://help.ubuntu.com/community/sane_Troubleshooting

'

# Mint keeps dropping the scanner out of the 'scanner' group.
## Check to see that the device still belongs to it. Find the Bus/Device:
scAll=$(lsusb | grep 'Perfection V30')
scBus=$(echo "$scAll" | egrep -o 'Bus ([0-9][0-9][0-9])' | sed 's/.* //')
scDev=$(echo "$scAll" | egrep -o 'Device ([0-9][0-9][0-9])' | sed 's/.* //')
if [[ -n "$scBus" && -n "$scDev" ]]; then
    scPath="/dev/bus/usb/$scBus/$scDev"
    scGrp=$(stat -c %G "$scPath")
    if [[ "$scGrp" != "scanner" ]]; then
        echo -e "\033[35m
The USB bus handling the scanner does not belong to the proper group. Please
run the following to allow the script to function:
    sudo chgrp scanner $scPath
\033[0m"
        exit
    fi
    ## Ok, everything seems good
else
    echo -e"\033[35m
... failed to determine Bus/Device for scanner ...
    If scanning fails, try to determine if the USB mount has the correct
    group assignment ('scanner', instead of 'root')
\033[0m"
fi

## You'll likely need to change these two values:
## The name of the scanner, use scanimage -L to find out what yours is:
DEVNAME='epkowa'
## The folder where the scanned images should be stored:
DIR='/abyss/Common/ToFile/Scanner'


## use scanimage -L and grep to get the full device name, including
## the USB numbering:
DEVICE=`scanimage -L | egrep -o "$DEVNAME:[a-z]+:[0-9]+:[0-9]+"`

if [[ ! "$DEVICE" ]]; then
    
    echo -e "
  \033[102;31m  Failed to locate device '$DEVNAME'  \033[0m
"
    exit
fi

FILE=`date +'scannedImage_%Y-%m-%d_%H:%M:%S'`
CMD="scanimage --progress --mode color"

CMD="$CMD --format=tiff";
# CMD="$CMD --progress";
FILE="$FILE.tiff";

FILEPATH="$DIR/$FILE"

echo -e "
Scanning document:
  From: \033[35m$DEVICE\033[0m
    To: \033[34m$DIR
\033[31m"

`$CMD  -d "$DEVICE" > $FILEPATH`

echo -e "\033[0m
  File: \033[36m$FILE\033[0m
"

sleep 10
