#!/bin/bash

# Usage: ./FilePortPilot.sh source_directory destination_directory port remote_host remote_user ssl_cert_path

SOURCE=$1
DESTINATION=$2
PORT=$3
REMOTE_HOST=$4
REMOTE_USER=$5
SSL_CERT_PATH=$6

# Debugging: Print the paths being used
echo "Source: $SOURCE"
echo "Destination: $DESTINATION"
echo "Port: $PORT"
echo "Remote Host: $REMOTE_HOST"
echo "Remote User: $REMOTE_USER"
echo "SSL Cert Path: $SSL_CERT_PATH"

# Extract the remote directory path
REMOTE_DIR=$(dirname "$DESTINATION")

# Ensure the destination directory exists on the remote server
ssh -i $SSL_CERT_PATH -p $PORT $REMOTE_USER@$REMOTE_HOST "mkdir -p $REMOTE_DIR"

# Check if the link-dest directory exists on the remote server
if ssh -i $SSL_CERT_PATH -p $PORT $REMOTE_USER@$REMOTE_HOST "[ -d $DESTINATION ]"; then
    LINK_DEST_OPTION="--link-dest=$DESTINATION"
else
    LINK_DEST_OPTION=""
fi

# Perform the rsync with hard links for incremental backup on the remote server using the specified SSL certificate
rsync -avz -e "ssh -i $SSL_CERT_PATH -p $PORT" --delete $LINK_DEST_OPTION $SOURCE $REMOTE_USER@$REMOTE_HOST:$DESTINATION
