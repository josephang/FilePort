#!/bin/bash

while getopts l:u:i:s:r:h:p: flag
do
    case "${flag}" in
        l) localdir=${OPTARG};;
        u) remotedir=${OPTARG};;
        i) localuser=${OPTARG};;
        s) sslcert=${OPTARG};;
        r) remoteuser=${OPTARG};;
        h) remotehost=${OPTARG};;
        p) port=${OPTARG};;
    esac
done

echo "Uploading $localdir to $remotehost:$remotedir"
rsync -avz -e "ssh -i $sslcert -p $port" --exclude '*/.*' $localdir $remoteuser@$remotehost:$remotedir

echo "Upload complete: $localdir to $remotehost:$remotedir"
