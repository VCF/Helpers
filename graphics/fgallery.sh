#!/bin/bash

SourceDir="$1"

if [[ -z "$SourceDir" ]]; then
    echo "
Please provide the source folder of images as the first argument
"
    exit
fi

if [[ -d "$SourceDir/gallery" ]]; then
    echo "
Folder appears to already have an image gallery at:
  $SourceDir/gallery
  Remove that folder if you wish to recalculate
"
    exit
fi

trg=$(mktemp -u) # 'dry run' to just get a temp name

echo "
Creating HTML image gallery for:
  $SourceDir
"

fgallery \
    -d           `# do not generate a full album download` \
    -i           `# improve thumbnail cutting by performing face detection` \
    "$SourceDir" `# Input directory` \
    "$trg"       `# Specify gallery directory location` \
    "$SourceDir" `# Gallery name`

cd "$SourceDir"

if [[ ! -s "README" ]]; then
    echo "
A web gallery is available in gallery/index.html
" > README
fi

## Move temporary directory into a 'gallery' folder in the source images
gdir="gallery"
mv "$trg" "$gdir"
if [[ -d "$gdir" ]]; then
    echo "
Gallery created in:
  $SourceDir/$gdir
"
    # Remove duplicate hi-res files, replace with symlinks
    cd "$gdir/files"
    for filename in *.*; do
        target="../../$filename"
        if [[ -e "$target" ]]; then
            ## Replace copies of files with symlinks
            rm "$filename"
            ln -s "$target" .
        fi
        if [[ ! -s "README" ]]; then
            echo "
Symlinks to full-resolution original files
" > README
        fi
    done
else
    echo "
?? Error moving gallery to photo folder."
    if [[ -d "$trg" ]]; then
        echo "   Gallery appears to be here: $trg"
    else
        echo "   I can't find the gallery!?!"
    fi
fi

