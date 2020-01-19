#!/usr/bin/env bash

DRIVE="$1"

if [[ -z "$DRIVE" ]]; then
    echo "Please provide the path to the drive being synchronized as the first argument"
    exit
fi

if [[ ! -d "$DRIVE" ]]; then
    echo "Your requested backup drive:
  $DRIVE
... does not appear to be a directory"
    exit
fi

optFile="$DRIVE/backupSettings.sh"

if [[ ! -s "$optFile" ]]; then
    echo "#!/usr/bin/env bash

## This script configures the rsync properties for this backup drive

## Define the source folders you wish to backup here, one per line:

sourceDirs=\"
/bogus/example/directory
/another/bogus/example
\"


" > "$optFile"
    chmod u+x "$optFile"
    
    echo "A blank settings file has been created at:

  $optFile

Please edit that file and follow the instructions inside it to configure
your drive for backups.
"
    exit
fi

## Source the configuration file
. "$optFile"

if [[ -z "$sourceDirs" ]]; then
    echo "Configuration file read:
$sourceDirs
  ... but it appears to have not defined 'sourceDirs'
"
    exit
else
    echo "
Settings read: $optFile
"
fi

logDir="$DRIVE/backupLogs"
[[ -d "$logDir" ]] || mkdir -p "$logDir"
NOW=`date '+%Y-%m-%d'`
REPORT="$logDir/rsync-report-$NOW.txt";
echo "rsync progress will be written to:
  $REPORT
Follow in another terminal with:
  tail -f "$REPORT"
"


## Split string on newlines: https://stackoverflow.com/a/19772067
IFS=$'\n' read -rd '' -a sourcePaths <<< "$sourceDirs"

donePaths=""
failPaths=""
for path in "${sourcePaths[@]}"
do
    ## Trim trailing slashes and whitespace from path:
    path="$(sed 's=[/ ]*$==g' <<< "$path")"
    ## Trim leading  whitespace:
    path="$(sed 's=^ *==' <<< "$path")"
    if [[ -n "$path" ]]; then
        ## path is non-blank
        if [[ ! -d "$path" ]]; then
            echo "Could not find requested source directory:
  $path
"
            failPaths="$failPaths
  $path"
            continue
        fi
        TARG="$(sed 's=//*=/=g' <<< "$DRIVE/$path")"
        [[ -d "$TARG" ]] || mkdir -p "$TARG"
        echo "Synchronizing source:
  '$path'
    to
  '$TARG'
"
        rsync -avh \
              "$path/" \
              "$TARG" \
              >> "$REPORT"
        donePaths="$donePaths
$path -> $TARG"
    fi
done

if [[ -n "$donePaths" ]]; then
    echo "The following directories were synchronized:
$donePaths
"
else
    echo "No valid directories found!"
fi

if [[ -n "$failPaths" ]]; then
    echo "
Some requested directories could not be found:
$failPaths
"
fi
