#!/bin/bash

## Simple script to use scanimage to scan multiple pages from the page
## feeder of a Brother ADS-2000. Works flawlessly on Linux Mint with
## Brother's drivers:

## http://support.brother.com/g/b/downloadtop.aspx?c=us&lang=en&prod=ads2000_us

## Mint keeps dropping the scanner out of the 'scanner' group.
## Check to see that the device still belongs to it. Find the Bus/Device:
scAll=$(lsusb | grep Brother)
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

##### Create output directory for today's date #####
## Directories are of course local to my network...
## Scratch space on badger:
outDir='/media/BadgerStore/scanned'
if [ ! -d "$outDir" ]; then
    # If it does not exist, use the ToFile section
    outDir='/abyss/Common/ToFile/Scanner'
    mkdir -p $outDir
fi
SUBDIR=$(date +'%Y-%m-%d')
outDir="$outDir/$SUBDIR"
mkdir -p $outDir
cd $outDir

## Files will be named by Hr:Min:Sec, and the '%d' will be interpreted
## by scanimage to automatically number each page as it's scanned:
FILE=$(date +'zzScan.%H:%M:%S.%%d.tiff')

CMD=$(which scanimage)
CMD="$CMD --progress"
## CMD="$CMD --mode color" # Is default, I think?

## I generally feed these images into tesseract for OCR
## processing. Tesseract consumes high-resolution TIFF documents:
CMD="$CMD --format=tiff --progress --batch=$FILE";

## To see scanner-specific options:
## scanimage --all-options

# Brother ADS-2000
CMD="$CMD --resolution=400"
#CMD="$CMD --mode='24bit Color'"
#CMD="$CMD --source='Automatic Document Feeder(centrally aligned,Duplex)'"

IMGPATH="$outDir/$FILE"

echo
echo -e "Scanning document to \033[34m$outDir\033[31m"
START=$(date +'%H:%M:%S')
echo "START: $START"
echo $CMD

$CMD  --mode='24bit Color'  \
      --source='Automatic Document Feeder(centrally aligned,Duplex)' \
      2>&1 | egrep -v "(Scanned page|rounded value)"

echo -e "\033[32m$FILE\033[0m"
END=$(date +'%H:%M:%S')
echo "END: $END"
echo
