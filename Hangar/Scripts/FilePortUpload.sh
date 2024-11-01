#!/bin/bash

while getopts l:u:i:s:r:h:p:b:m: flag
do
    case "${flag}" in
        l) localdir=${OPTARG};;
        u) remotedir=${OPTARG};;
        i) localuser=${OPTARG};;
        s) sslcert=${OPTARG};;
        r) remoteuser=${OPTARG};;
        h) remotehost=${OPTARG};;
        p) port=${OPTARG};;
        b) bwlimit=${OPTARG};;
        m) mainconfigpath=${OPTARG};;
    esac
done

retry_attempts=$(jq -r '.retry_attempts' $mainconfigpath)
attempt=0
success=false

while [ $attempt -lt $retry_attempts ]; do
    echo "Uploading $localdir to $remotehost:$remotedir (Attempt $((attempt+1))/$retry_attempts)"
    rsync -avz --partial --progress --bwlimit=$bwlimit -e "ssh -i $sslcert -p $port" --exclude '*/.*' $localdir $remoteuser@$remotehost:$remotedir
    if [ $? -eq 0 ]; then
        success=true
        break
    fi
    attempt=$((attempt+1))
    echo "Upload failed, retrying..."
done

if [ "$success" = true ]; then
    echo "Upload complete: $localdir to $remotehost:$remotedir"
else
    echo "Upload failed after $retry_attempts attempts"
fi
