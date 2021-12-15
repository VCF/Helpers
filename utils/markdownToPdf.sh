#!/usr/bin/env bash

## Wrapper to take a single markdown file and pass it through pandoc
## to generate a PDF, since pandoc's parameters are non-intuitive

## Dependencies that may need to be installed:
##   sudo apt-get install pandoc pdflatex texlive-latex-base texlive-fonts-recommended texlive-extra-utils texlive-latex-extra

md="$1"

if [[ -z "$md" ]]; then
    echo "Provide a path to a markdown file as the first argument,
   and pandoc will be used to generate a PDF from it"
    exit
fi

## Strip markdown suffix and add .pdf
out=$(echo "$md" | sed s/'.md$'//)".pdf"

echo "
Input:  $md
Output: $out
"

## Output format is *not* 'pdf'. Use 'beamer' for slide generation

pandoc \
    --from=markdown \
    --to=latex \
    --output="$out" \
    "$md"

if [[ -s "$out" ]]; then
    chk=$(file "$out" | grep -o "PDF document")
    if [[ "$chk" == "PDF document" ]]; then
        echo "Document appears to have been succesfully created:"
    else
        echo "[!!] File was generated, but may not be PDF?"
    fi

else
    echo "[!!] Could not find output file:"
fi
echo "  '$out'"
