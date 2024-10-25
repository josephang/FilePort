#!/bin/bash

# Usage: ./FilePortPilot.sh source_directory destination_directory port remote_host remote_user ssl_cert_path main_config_file

SOURCE=$1
DESTINATION=$2
PORT=$3
REMOTE_HOST=$4
REMOTE_USER=$5
SSL_CERT_PATH=$6
MAIN_CONFIG_FILE=$7

# Source the main configuration file
source "$(dirname "$0")/FilePortConfig.sh" "$MAIN_CONFIG_FILE"

# Logging function
log_message() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" >> "$LOG_FOLDER/$LOG_FILE_NAME"
}

# Debugging: Print the paths being used
log_message "INFO" "Source: $SOURCE"
log_message "INFO" "Destination: $DESTINATION"
log_message "INFO" "Port: $PORT"
log_message "INFO" "Remote Host: $REMOTE_HOST"
log_message "INFO" "Remote User: $REMOTE_USER"
log_message "INFO" "SSL Cert Path: $SSL_CERT_PATH"
log_message "INFO" "Server Name: $SERVER_NAME"
log_message "INFO" "Log Folder: $LOG_FOLDER"
log_message "INFO" "Log File Name: $LOG_FILE_NAME"

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

# Function to perform rsync with retries
perform_rsync() {
    local attempt=1
    while [ $attempt -le $RETRY_ATTEMPTS ]; do
        rsync -avz -e "ssh -i $SSL_CERT_PATH -p $PORT" --delete $LINK_DEST_OPTION "$SOURCE/" "$REMOTE_USER@$REMOTE_HOST:$DESTINATION"
        if [ $? -eq 0 ]; then
            log_message "INFO" "Backup completed from $SOURCE to $DESTINATION on attempt $attempt"
            return 0
        else
            log_message "ERROR" "Rsync failed on attempt $attempt"
            attempt=$((attempt + 1))
        fi
    done
    log_message "ERROR" "Rsync failed after $RETRY_ATTEMPTS attempts"
    return 1
}

# Perform the rsync with retries
perform_rsync
