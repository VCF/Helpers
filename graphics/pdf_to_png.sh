#!/bin/bash

## Convert a single PDF file into a set of PNG files, one per page

PDF="$1"

[[ -z "$PDF" ]] && echo "Please provide the path to PDF file" && exit

OUT="$2"

if [[ -z "$OUT" ]]; then
    ## No output file provided, make one based on provided name
    OUT=`echo "$PDF" | sed 's/\.[^\.]*$/.png/'`
    ## Safety check
    [[ "$PDF" == "$OUT" ]] && echo "Failed to create new output name!" && exit
fi

echo "

Converting ...

"

## All the convert bits from @JBWhitmore at:
##   https://stackoverflow.com/a/6605085
convert -verbose -density 150 -trim "$PDF" \
    -quality 100 -sharpen 0x1.0 "$OUT"

echo "
Output written to one or more files based on:
  $OUT
"

