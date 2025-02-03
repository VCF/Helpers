#!/bin/bash

README="
downloadManifest.sh
Utility allowing text files to specify URLs which are then downloaded locally. 

A single argument specifies the path to the text file
* Lines starting with 'https://' are treated as a URL to retrieve
* Lines starting with letters then an equal sign are options, eg
  DIR=myDownloadedFiles
* All other lines are ignored

Available options:
All options are case insensitive. Options can be set anywhere in the manifest,
can be reset any number of times, and will affect all URLs that follow.

       DIR The directory to download files to. If the value starts
           with '/' it will be treated as an absolute path, otherwise
           will be relative to the manifest.  Default: '../downloads'

    SUBDIR Optional subdirectory relative to DIR

    USETOR Any non-blank value will cause download to be wrapped in torsocks,
           causing the file recovery to use the Tor network

    METADB Path to an optional SQLite database that will be used to
           track metadata about each file, avoid repeat downloads, and
           manage failed attempts

    DUPEDB Path to an optional dupliate image database used to prevent
           re-adding the same image to the collection.

   MAXSIZE For images, the desired maximum file size, in KB
           Default 300

   MINSAVE When resizing, give up (keep original file) if percentage
           size savings is less than this value. For example, if a
           100kb file is reduced to 80kb, you've saved 20%
           ('20'). Default 50

"



## script folder: https://stackoverflow.com/a/246128
myLaunchDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$myLaunchDir/../_util_functions.sh"

## File path to manifest
MANIFEST="$1"

if [[ ! "$MANIFEST" ]]; then
    note "$README"
    warn "You need to provide the path to the URL manifest"
    exit
elif [[ ! -f "$MANIFEST" ]]; then
    error "Manifest file not found: $MANIFEST"
    exit
fi

chk=$(which convert)
if [[ "$chk" == "" ]]; then
        error "The program requires ImageMagick to be installed:
  sudo apt install imagemagick"
        exit
fi


## Directory holding manifest:
mDir=$(dirname "$MANIFEST")
## Working directory
tempDir="$mDir/temp"
wgetLog="$tempDir/wget.log"

## Default configuration, can be changed in manifest
## The base folder for holding downloaded files
baseDir="$mDir/downloads"

## Logfile for STDERR and various information
logFile="$mDir/processingLog.txt"

## Subdirectory relative to base directory
subDir=""
## If torsocks should be used (will be needed for onion sites)
useTor=""
## Optional SQLite database file to maintain metadata
metaDB=""
## Optional image duplication database (findimagedupes)
dupeDB=""
## Maximum file size in kb
maxSize="300"
## Minimum file compression to keep resize:
minSave="50"

mLine=$(wc -l "$MANIFEST" | sed 's/ .*//')
mSize=$(ls -1s "$MANIFEST" | sed 's/ .*//')

msg "$FgGreen" "Parsing $MANIFEST: $mLine lines, ${mSize}kb"
echo "######## $(date +"%Y-%m-%d %H:%M%p") $mLine lines, ${mSize}kb ########
$MANIFEST
" >> "$logFile"

echo "######## $(date +"%Y-%m-%d %H:%M%p") $mLine lines, ${mSize}kb ########
$MANIFEST
" > "$wgetLog"

function fileType {
    path="${1,,}"
    ## Strip off any GET parameters after '?'
    ## Keep only last text after '.'
    sfx=$(echo "$path" | sed 's/\?.*$//' | grep -o '[^\.]*$' )
    if [[ $sfx == "jpg" || $sfx == "jpeg" ]]; then
        echo "jpg";
    elif [[ $sfx == "png" || $sfx == "gif" || $sfx == "webp" ||
                $sfx == "html" ]]; then
        echo "$sfx";
    else
        info "Unanticipated file type: $sfx"
        echo "$sfx";
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

function aniGif {
    ## Check if a file is an animated GIF
    ## Relevant because we don't want to attempt resizing these
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

function resize {
    path="$1"
    if [[ "$maxSize" == "" ]]; then
        ## Resizing turned off, keep original file
        echo "$path"
        return
    fi
    ft=$(fileType "$path")
    if [[ $ft != "jpg" && $ft != "png" && $ft != "webp" && $ft != "gif" ]]; then
        ## The file does not appear to be an image
        # echo "Non-image: $path" >> "$logFile"
        echo "$path"
        return
    fi
    isAni=$(aniGif "$path")
    if [[ "$isAni" == "TRUE" ]]; then
        ## The file appears to be an animated gif, do not attempt resize
        echo "$path"
        return
    fi

    ## See if resizing gets us the savings we requested
    srcSz=$(filesz "$path")
    ## Convert to a temp file
    rsFile="$path.resize.jpg"
    rm -f "$rsFile"
    ## ImageMagick's convert utility
    ## The extent flag allows a requested file size to be set
    convert "$path" \
            -define jpeg:extent="$maxSize"kb \
            "$rsFile" \
            > "STDERR.txt" 2>&1
    
    if [[ ! -s "$rsFile" ]]; then
        echo "Failed to resize: $path" >> "$logFile"
        echo "$path"
        return
    fi

    outSz=$(filesz "$rsFile")
    reduce=$((100 * ($srcSz - $outSz) / $srcSz))

    if [[ $reduce -lt $MINSAVE ]]; then
        ## Conversion was "not worth it"
        echo "$path"
        return
    fi
    echo "RESIZED: ${reduce}% savings: $path" >> "$logFile"
    echo "$rsFile"
}

function downloadFile {
    url="$1"
    stat=$(urlStatus "$url")
    if [[ "$stat" == "PASS" ]]; then
        msg "$FgWhite" "Already Done: $url";
        return
    elif [[ "$stat" == "FAIL" ]]; then
        msg "$FgCyan" "Retry: $url";
    fi

    name=$(basename "$url")
    ft=$(fileType "$name")
   
    ## We will download to a temp location to assess success and be
    ## somewhat atomic:
    mkdir -p "$tempDir"
    tmp="$tempDir/$name"
    [[ -f "$tmp" ]] && rm "$tmp" # Remove file if already there

    cd "$tempDir"
    CMD="wget"
    [[ $useTor != "" ]] && CMD="torsocks $CMD"
    CMD="$CMD -a \"$wgetLog\"" # messages to logfile
    CMD="$CMD \"$url\""        # URL To get
    eval "$CMD"

    if [[ ! -f "$name" ]]; then
        warn "Failed to download: $url"
        x=$(urlStatus "$url" "FAIL")
        return
    elif [[ ! -s "$name" ]]; then
        warn "Downloaded zero-length file: $url"
        x=$(urlStatus "$url" "FAIL")
        return
    fi

    ## We appear to have downloaded the file
    ## Go through resize check and process:
    name=$(resize "$name")
    sz=$(filesz "$name")
    ft=$(fileType "$name")
    cs=$(md5sumFile "$name" "$url")
        
    targ="$baseDir"
    [[ "$subDir" != "" ]] && targ="$baseDir/$subDir"
    if [[ ! -d "$targ" ]]; then
        mkdir -p "$targ"
        if [[ ! -d "$targ" ]]; then
            error "Failed to create download directory: $targ"
            exit
        fi
        info "Directory created: $targ"
    fi
    ## Rename the file to its checksum, and move it to the desired destination
    targPath="$targ/$cs.$ft"
    mv "$name" "$targPath"

    if [[ ! -s "$targPath" ]]; then
        error "File was downloaded, but somehow failed to move to destination"
        x=$(urlStatus "$url" "FAIL")
    fi
        
    ## We seem to have succeeded
    x=$(urlStatus "$url" "PASS")
    if [[ "$metaDB" != "" ]]; then
        ## Record details in metadata database
        sqlite3 "$metaDB" <<EOF
UPDATE urls
   SET md5 = "$cs", type = "$ft", path = "$targPath", size = "$sz"
 WHERE url = "$url"
EOF
           
    fi
    msg "$BgWhite;$FgGreen" "$cs.$ft ${sz}kb - $url"
 }

function md5sumFile {
    path="$1"
    u="$2"
    if [[ ! -s "$path" ]]; then
        echo "0000"
        return
    fi
    cs=$(md5sum "$path" | sed 's/ .*//')
    echo "$cs"
}

function setupDatabase {
    ## Non-interactive SQLite
    ##    https://stackoverflow.com/a/42245911
    path="$1"
    if [[ "$path" == "" ]]; then
        info "SET: Metadata DB = Disabled"
        metaDB=""
        return
    fi
    
    chk=$(which "sqlite3")
    if [[ "$chk" == "" ]]; then
        error "Tracking file metadata requires SQLite:
  sudo apt install sqlite3
  Metadata database functionaliy not available"
        exit
    fi
    chk2=$(sqlite3 --version | egrep -o '^[0-9]*\.[0-9]*' )
    if [[ $chk2 < 3.24 ]]; then
        error "sqlite3 is version $chk2, 3.24 required for UPSERT commands
  Metadata database functionaliy not available"
        return
    fi
    
    if [[ $(grepPattern "^/" "$path") == "" ]]; then
        ## Database defined relative to manifest
        path="$mDir/$path"
    fi
    metaDB="$path"
    if [[ -s "$metaDB" ]]; then
        ## Database already exists
        info "SET: Metadata DB = $metaDB"
        return
    fi
    
    ## We need to create the DB
    sqlite3 "$metaDB" <<EOF
CREATE TABLE urls (url TEXT PRIMARY KEY, type TEXT, md5 TEXT, status TEXT, size INTEGER, path TEXT);
CREATE INDEX urlmd5 on urls (md5);
CREATE TABLE tagval (md5 TEXT, tag TEXT, val TEXT);
CREATE INDEX mdTag on tagval (md5, tag);
CREATE INDEX tv on tagval (tag, val);
EOF

    if [[ -s "$metaDB" ]]; then
        ## Success
        info "SET: Metadata DB (Created) = $metaDB"
    else
        error "Failed to create metadata database: $metaDB"
        exit
    fi
}

function urlStatus {
    ## 'status' tracks the success of downloading the file
    [[ $metaDB == "" ]] && return
    u="$1"
    v="$2"
    if [[ "$v" != "" ]]; then
        ## This is a set request
        ## We will use the non-standard UPSERT
        sqlite3 "$metaDB" <<EOF
INSERT INTO urls (url, status) VALUES ("$u", "$v")
 ON CONFLICT(url) DO UPDATE SET status=excluded.status;
EOF
        echo "$v"
    else
        ## Get request
        echo $(sqlite3 "$metaDB" "SELECT status FROM urls WHERE url='$u'")
    fi
}

function urlType {
    ## 'type' tracks the file type associated with the URL
    [[ $metaDB == "" ]] && return
    u="$1"
    v="$2"
    if [[ "$v" != "" ]]; then
        ## This is a set request
        ## We will use the non-standard UPSERT
        sqlite3 "$metaDB" <<EOF
INSERT INTO urls (url, type) VALUES ("$u", "$v")
 ON CONFLICT(url) DO UPDATE SET status=excluded.type;
EOF
        echo "$v"
    else
        ## Get request
        echo $(sqlite3 "$metaDB" "SELECT type FROM urls WHERE url='$u'")
    fi
}

function setConf {
    txt="$1"
    KEY=$(echo "$txt" | sed 's/=.*//')
    ## Uppercase: https://stackoverflow.com/a/11392248
    KEY=${KEY^^}
    VAL=$(echo "$txt" | sed 's/^[A-Za-z]*=//')

    if [[ "$KEY" == "USETOR" ]]; then
        ## Configuring if torsocks is used
        if [[ "$VAL" == "" ]]; then
            info "SET: Tor = Off"
            useTor=""
        else
            chk=$(which torsocks)
            if [[ "$chk" == "" ]]; then
                error "Using Tor requires torsocks:
  sudo apt install torsocks"
                exit
            fi
            info "SET: Tor = On"
            useTor="TRUE"
        fi
    elif [[ "$KEY" == "DIR" ]]; then
        ## Setting the base directory for downloads
        if [[ $(grepPattern "^/" "$VAL") != "" ]]; then
            ## This is an absolute file path
            info "SET: Download directory (absolute) = $VAL"
            baseDir="$VAL"
        else
            ## This is a relative path to the manifest
            info "SET: Download directory (relative) = $VAL"
            baseDir="$mDir/$VAL"
        fi
        cd "$baseDir"
    elif [[ "$KEY" == "SUBDIR" ]]; then
        if [[ "$VAL" == "" ]]; then
            info "CLEAR: Subdirectory cleared"
            cd "$baseDir"
        else
            info "SET: Download subdirectory = $VAL";
            cd "$baseDir/$VAL"
        fi
        subDir="$VAL"
    elif [[ "$KEY" == "METADB" ]]; then
        setupDatabase "$VAL"
    elif [[ "$KEY" == "HALT" ]]; then
        ## Command to stop processing of the file at this point
        if [[ "$VAL" != "" ]]; then
            note "Request to halt processing"
            HALT="Yes"
        fi
    elif [[ "$KEY" == "DUPEDB" ]]; then
        chk=$(which findimagedupes)
        if [[ "$chk" == "" ]]; then
            error "Duplicate image checking requires package installation:
  sudo apt install findimagedupes"
            exit
        fi
        dupeDB="$VAL"
    elif [[ "$KEY" == "MAXSIZE" ]]; then
        if [[ "$VAL" == "" ]]; then
            info "CLEAR: Resizing turned off"
        else
            info "SET: Max image size = $VAL";
        fi
        maxSize="$VAL"
    elif [[ "$KEY" == "MINSAVE" ]]; then
        if [[ "$VAL" == "" ]]; then
            info "CLEAR: Minimum percent saving threshold turned off"
        else
            info "SET: Minimum savings threshold = $VAL";
        fi
        minSave="$VAL"
    elif [[ "$KEY" == "" ]]; then
        foo=1
    else
        warn "Unknown config key: $KEY"
    fi
}

## Read line-by-line: https://stackoverflow.com/a/10929511
while IFS= read -r line; do
    [[ "$HALT" == "" ]] || break
    if [[ ! "$line" ]]; then
        BLANK=1 ## No-op for blank lines
    elif [[ $(grepPattern "^https://" "$line") != "" ]]; then
        downloadFile "$line"
    elif [[ $(grepPattern "^[A-Za-z]*=" "$line") != "" ]]; then
        setConf "$line"
    fi
done < "$MANIFEST"

[[ "$logFile" == "" ]] || info "Logfile at: $logFile"
