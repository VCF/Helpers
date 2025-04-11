
#!/usr/bin/env bash

## Simple argument parsing
##   https://stackoverflow.com/a/33826763
TARGET="" OUTSIZE=300 FACTOR=2 MINSAVE=50
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -o|--outsize) OUTSIZE="$2"; shift ;;
        -t|--threshold) FACTOR="$2"; shift ;;
        -m|--minsavings) MINSAVE="$2"; shift ;;
        *) TARGET="$1"; break ;;
    esac
    shift
done

if [[ -z "$TARGET" ]]; then
    echo -e "\033[1;31m

Please provide the folder of images as the first argument. Full arguments:

  * Folder to be processed
  * Desired output size, in kb (Default '300')
  * Threshold factor for input files (Default '2')
      That is, do not try to convert files unless they're 2x as large
      as desired output
  * Minimum percent savings (Default '50')
      That is, do not bother converting unless you can acheive at least
      50% size savings

\033[0m
"
    exit
fi

if [[ ! -d "$TARGET" ]]; then
    echo -e "
You requested processing images from:
  \033[1;34m${TARGET}\033[0m
... \033[1;31mbut that's not a directory\033[0m
"
    exit;
fi

## Math in base:
##  https://unix.stackexchange.com/a/299327
GETSIZE=$(( $FACTOR * $OUTSIZE ))

## Where the resized files will be written
OUTPUT="$TARGET/resized"
if [[ -d "$OUTPUT" ]]; then
    echo -e "
The output folder already exists:
  \033[1;34m${OUTPUT}\033[0m
\033[1;31mPlease delete or rename that folder to proceed.\033[0m
"
    exit;
fi
mkdir -p "$OUTPUT"

echo -e "
Searching for images in:
  \033[1;34m${TARGET}\033[0m
Finding images  >= \033[1;31m${GETSIZE} kb\033[0m
Reducing images to \033[1;32m${OUTSIZE} kb\033[0m
Writing images to:
  \033[1;34m${OUTPUT}\033[0m
"
# exit

found=$(find "$TARGET" -maxdepth 1 -size "+${GETSIZE}k" -and \
     -iname '*.jpg' -or \
     -iname '*.jpeg' -or \
     -iname '*.png' -or \
     -iname '*.webp' -or \
     -iname '*.orf' -or \
     -iname '*.gif' | \
    sed 's/.*\///')

## Find script directory
##   https://stackoverflow.com/a/246128
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

## We'll make an HTML document to preview the images
indx="$OUTPUT/index.html"
echo "<html><head>
<script>
" > "$indx"

## Javascript held in sidecar file:
cat "$SCRIPT_DIR/shrinkJS.js" >> "$indx"

echo "
</script>
<style>
" >> "$indx"

## Styles held in sidecar file:
cat "$SCRIPT_DIR/shrinkCSS.css" >> "$indx"

echo "
</style>
</head><body class='small'>
<h2>Image comparison for $TARGET</h2>
<button onclick='togRes(event)'>Toggle Display Size</button><br>
" >> "$indx"


## We'll also make a script to remove any renamed originals
rmv="$OUTPUT/removeXtra.sh"
echo "#!/bin/bash
echo 'This script will remove any renamed original files'
cd \"$(pwd)/$TARGET\"

" >> $"rmv"

renamed="FALSE"
picClass="show"
navHTML="<button onclick='nextPic(event)'>Next &rarr;</button> - <button onclick='prevPic(event)'>&larr; Previous</button><br>"

function aniGif {
    ## Suffix extraction: https://stackoverflow.com/a/965069
    sfx="${1##*.}"
    if [[ "$sfx" == "gif" ]]; then
        ##  https://unix.stackexchange.com/q/224631
        ires=$(identify -format '%n %i\n' -- "$1" | wc -l)
        if [[ "$ires" == "1" ]]; then
            ## Single frame GIF
            echo "FALSE"
        else
            echo "TRUE"
        fi
    else
        ## Not a GIF
        echo "FALSE"
    fi
}

function filesz {
    ## Get size of a file
    ## Did not work:  https://unix.stackexchange.com/a/16645
    ## du -kh "$1" | cut -f1
    ##   https://unix.stackexchange.com/a/16644
    bytes=$(stat --printf="%s" "$1")
    echo $(( $bytes / 1024 ))
}
serr="${OUTPUT}/stderr.txt"

IFS=$'\n' read -rd '' -a SPLITLINES <<< "$found"
for file in "${SPLITLINES[@]}"; do
    path="$TARGET/$file"
    srcSz=$(filesz "$path")
    isAni=$(aniGif "$path")
    if [[ "$isAni" == "TRUE" ]]; then
        ## Animated gif, leave alone
        echo "<div class=\"$picClass\">
  $navHTML
  <div class='showOrig'>
    <button>No conversion</button> - <span class='noAct'>No conversion for animated GIFs</span>
    <h3>$file</h3>
    <div class='orig'><h4>Original ${srcSz} kb &rarr; <span class='noAct'>Left unmodified</span></h4><img src='../$file' /></div>
  </div>
</div>" >> "$indx"
        picClass="hide"
        continue
    fi
    
    ## Remove suffix
    ##   https://stackoverflow.com/a/125340
    base="${file%.*}"
    outbase="${base}.jpg"
    outfile="${OUTPUT}/$outbase"
    
    ## Use ImageMagick to reduce file size to a target:
    ##  https://stackoverflow.com/a/11920384
    convert "$path" \
            -define jpeg:extent="$OUTSIZE"kb \
            "$outfile" \
            > "$serr" 2>&1

    if [[ ! -s "$outfile" ]]; then
        ## Failed to find expected output
        stxt=$(cat "$serr")
        echo "<div class=\"$picClass\">
$navHTML
<h3>$file</h3>
<span class='err'>Failed to convert image file</span>
<pre>${TARGET}/${file}</pre>
<pre class='err'>$stxt</pre>
</div>" >> "$indx"
        picClass="hide"
        continue
    fi
    
    ## Ok, how big is the conversion, and how much have we saved?
    outSz=$(filesz "$outfile")
    reduce=$((100 * ($srcSz - $outSz) / $srcSz))

    if [[ $reduce -lt $MINSAVE ]]; then
        ## Conversion did not meet our desired file savings
        MSG="Conversion did not meet minimum savings of ${MINSAVE}%"
        if [[ $srcSz -lt $outSz ]]; then
            MSG="$MSG. <i>In fact, the converted image is larger</i>"
        fi
        echo "<div class=\"$picClass\">
  $navHTML
  <div class='showOrig'>
    <button>Undesired Conversion</button> - <span class='err'>$MSG</span>
    <h3>$file</h3>
    <div class='orig'><h4>Original ${srcSz} kb &rarr; Converted ${outSz} kb = <span class='err'>${reduce}%</span></h4><img src='../$file' /></div>
  </div>
</div>" >> "$indx"
        ## Remove the too-large file
        rm "$outfile"
        picClass="hide"
        continue
    fi

    ## Ok, it looks like we have a nicely reduced file
    echo "<div class=\"$picClass\">
  $navHTML
  <div class='showOrig'>
    <button onclick='swap(event)'>Swap</button>
    <h3>$file</h3>
    <div class='orig'><h4><span class='orsz'>Original ${srcSz} kb</span> &rarr; Converted ${outSz} kb = ${reduce}%</h4><img src='../$file' /></div>
    <div class='conv'><h4>Original ${srcSz} kb &rarr; <span class='cnsz'>Converted ${outSz} kb</span> = ${reduce}%</h4><img src='$outbase' /></div>
  </div>
</div>" >> "$indx"
    
    ## Make scripted note if we had to rename the file (filetype change):
    if [[ "$outbase" != "$file" ]]; then
        echo "rm \"$file\"" >> "$rmv"
        renamed="TRUE"
    fi
    picClass="hide"
done

echo "</body></html>" >> "$indx"

echo "
Preview index available at:
  file://$(pwd)/${indx}
"

if [[ "$renamed" == "TRUE" ]]; then
    echo "Script to remove renamed files from source directory:
  $rmv
"
else
    echo "

echo 'Ultimately, no files ended up being renamed'

" >> "$rmv"
    
fi
