#!/bin/bash

# Basically just a reminder of how to launch a randomized slide show
# with feh

FOLDER="${1:-.}"

echo "
Randomized slide show for folder:
  \"$FOLDER\"
"

feh \
    --recursive \
    --randomize \
    --auto-zoom \
    --slideshow-delay 10 \
    --quiet \
    --fullscreen \
    "$FOLDER"
