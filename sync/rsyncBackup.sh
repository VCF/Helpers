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

backupConfig="$DRIVE/backupConfig"
[[ -d "$backupConfig" ]] || mkdir "$backupConfig"
if [[ ! -d "$backupConfig" ]]; then
    echo "Failed to create the backup configuration directory on your drive:
  $backupConfig
Please verify the drive is writable by you.
"
    exit
fi

optFile="$backupConfig/backupSettings.sh"

if [[ ! -s "$optFile" ]]; then
    echo "#!/usr/bin/env bash

## This script configures the rsync properties for this backup drive

## It is read by the Helpers/sync/rsyncBackup.sh script
##   https://github.com/VCF/Helpers/blob/master/sync/rsyncBackup.sh

## Provide the path to the device holding this file to rsyncBackup.sh
## to re-run rsync on the directories below.

## Define the source folders you wish to backup here, one per line:

sourceDirs=\"
/bogus/example/directory
/another/bogus/example
\"

## When this file was generated, the drive was mounted at:
##   $DRIVE
## ... but that mount point might not be the same on subsequent runs.

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

## Assure log dir is present
logDir="$backupConfig/Logs"
[[ -d "$logDir" ]] || mkdir -p "$logDir"

## Set up log file:
NOW=`date '+%Y-%m-%d'`
REPORT="$logDir/rsync-report-$NOW.txt";
BAR="###############################################################"
echo "$BAR
rsync run for $NOW
  Backup drive mounted as: $DRIVE
START: $(date '+%H:%M %b %d')
$BAR
" > "$REPORT"

echo "rsync progress will be written to:
  $REPORT
Follow in another terminal with:
  tail -f \"$REPORT\"
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
        
        echo "Synchronizing:
Source: '$path'
Target: '$TARG'
"
        echo "
$BAR
SOURCE: '$path'
TARGET: '$TARG'
$BAR
" >> "$REPORT"
        
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

echo "
$BAR
END: $(date '+%H:%M %b %d')
$BAR
" >> "$REPORT"
