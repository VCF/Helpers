#!/bin/bash

## Scans a single image from a flatbed scanner, assigns a date-stamped
## name, stores in a folder for later editting / renaming

HELP='
## Needs package:
   sudo apt-get install xsltproc
## Needs drivers installed: 
   export pkgLoc="/abyss/Installers/Linux/Linux Drivers/Epson Scanner"
   sudo dpkg -i "$pkgLoc/iscan-data_1.26.0-1_all.deb"
   sudo dpkg -i "$pkgLoc/iscan_2.29.3-1~usb0.1.ltdl7_amd64.deb"
'

## You'll likely need to change these two values:
## The name of the scanner, use scanimage -L to find out what yours is:
DEVNAME='epkowa'
## The folder where the scanned images should be stored:
DIR='/abyss/Common/ToFile/Scanner'


## use scanimage -L and grep to get the full device name, including
## the USB numbering:
DEVICE=`scanimage -L | egrep -o "$DEVNAME:[a-z]+:[0-9]+:[0-9]+"`

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
