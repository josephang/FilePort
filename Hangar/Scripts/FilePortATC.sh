#!/bin/bash

while getopts m:c:u:b: flag
do
    case "${flag}" in
        m) mainconfigpath=${OPTARG};;
        c) compressconfigpath=${OPTARG};;
        u) uploadconfigpath=${OPTARG};;
        b) bwlimit=${OPTARG};;
    esac
done

root_dir=$(jq -r '.root_dir' $mainconfigpath)

if [ -n "$compressconfigpath" ]; then
    directories=$(jq -c '.directories[]' $compressconfigpath)
    for dir in $directories; do
        path=$(echo $dir | jq -r '.path')
        exclude=$(echo $dir | jq -c '.exclude')
        "$root_dir/FilePort/Hangar/Scripts/FilePortCompress.sh" -c $path -b $exclude -s $(jq -r '.compression_Folder' $compressconfigpath) -N $(jq -r '.server_name' $mainconfigpath) -J $(jq -r '.job_name' $compressconfigpath) -E $(jq -r '.encryption_key' $compressconfigpath) > $root_dir/FilePort/Hangar/Logs/FilePort.log 2>&1
    done
fi

if [ -n "$uploadconfigpath" ]; then
    directories=$(jq -c '.directories[]' $uploadconfigpath)
    for dir in $directories; do
        local=$(echo $dir | jq -r '.local')
        remote=$(echo $dir | jq -r '.remote')
        "$root_dir/FilePort/Hangar/Scripts/FilePortUpload.sh" -l $local -u $remote -i $(jq -r '.local_user' $uploadconfigpath) -s $(jq -r '.ssl_cert_path' $uploadconfigpath) -r $(jq -r '.remote_user' $uploadconfigpath) -h $(jq -r '.remote_host' $uploadconfigpath) -p $(jq -r '.port' $uploadconfigpath) -m $mainconfigpath -b $bwlimit > $root_dir/FilePort/Hangar/Logs/FilePort.log 2>&1
    done
fi

echo "Job complete" | mail -s "Job Status" $(jq -r '.smtp_to[]' $mainconfigpath)
