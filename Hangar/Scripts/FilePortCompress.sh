#!/bin/bash

while getopts c:b:s:N:J:E: flag
do
    case "${flag}" in
        c) compresspath=${OPTARG};;
        b) exclusions=${OPTARG};;
        s) compressionfolder=${OPTARG};;
        N) servername=${OPTARG};;
        J) jobname=${OPTARG};;
        E) encryptionkey=${OPTARG};;
    esac
done

filename="${servername}_${jobname}_$(basename $compresspath).tar.xz"
echo "Compressing $compresspath to $compressionfolder/$filename"
tar --exclude=$exclusions -cJf $compressionfolder/$filename $compresspath

if [ -n "$encryptionkey" ]; then
    echo "Encrypting $compressionfolder/$filename"
    openssl enc -aes-256-cbc -salt -pbkdf2 -in $compressionfolder/$filename -out $compressionfolder/$filename.enc -pass pass:$encryptionkey
    rm $compressionfolder/$filename
    filename="$filename.enc"
fi

echo "Compression and encryption complete: $compressionfolder/$filename"
