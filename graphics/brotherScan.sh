#!/bin/bash

## Simple script to use scanimage to scan multiple pages from the page
## feeder of a Brother ADS-2000. Works flawlessly on Linux Mint with
## Brother's drivers:

## http://support.brother.com/g/b/downloadtop.aspx?c=us&lang=en&prod=ads2000_us

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
