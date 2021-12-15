#!/bin/bash

## Converts an image file to a base64 string. Useful for explicitly
## embedding images into CSS.

if [[ -z "$1" ]]; then
    echo "
Please provide the path to the image as the first argument
"
    exit
fi

echo ""
## If line wrapping is desired, run without the `-w 0` flag
base64 -w 0 "$1"
echo "
"

## Nothing special, just I always have to StackExchnage the answer
## since I don't need to do this often
##    https://stackoverflow.com/a/16918741

