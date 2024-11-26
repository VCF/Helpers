#!/bin/bash

# Basically just a reminder of how to launch a randomized slide show
# with feh

FOLDER="${1-:.}"

feh \
    --recursive \
    --randomize \
    --auto-zoom \
    --slideshow-delay 10 \
    --quiet \
    --geometry 1600x1000 \
    "$FOLDER"
