#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq to proceed."
    exit 1
fi

# Check if a directories configuration file is provided as a command-line argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directories_config_file.json>"
    exit 1
fi

DIRECTORIES_CONFIG_FILE="$1"
MAIN_CONFIG_FILE="/FilePort/Hangar/Configs/main_config.json"

# Check if the main configuration file exists
if [ ! -f "$MAIN_CONFIG_FILE" ]; then
    echo "Main configuration file not found: $MAIN_CONFIG_FILE"
    exit 1
fi

# Check if the directories configuration file exists
if [ ! -f "$DIRECTORIES_CONFIG_FILE" ]; then
    echo "Directories configuration file not found: $DIRECTORIES_CONFIG_FILE"
    exit 1
fi

# Read the main configuration file
SERVER_NAME=$(jq -r '.server_name' "$MAIN_CONFIG_FILE")
LOG_FOLDER=$(jq -r '.log_folder' "$MAIN_CONFIG_FILE")
LOG_FILE_NAME=$(jq -r '.log_file_name' "$MAIN_CONFIG_FILE")
LOG_KEEP_DAYS=$(jq -r '.log_keep_days' "$MAIN_CONFIG_FILE")

# Logging function
log_message() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" >> "$LOG_FOLDER/$LOG_FILE_NAME"
}

# Read the directories configuration file
RUNWAY_FOLDER=$(jq -r '.RunWay_Folder' "$DIRECTORIES_CONFIG_FILE")
BACKUP_FILE_NAME=$(jq -r '.backup_file_name' "$DIRECTORIES_CONFIG_FILE")
DIRECTORIES=$(jq -c '.directories[]' "$DIRECTORIES_CONFIG_FILE")
ENCRYPTION_ENABLED=$(jq -r '.encryption_enabled' "$DIRECTORIES_CONFIG_FILE")
ENCRYPTION_KEY=$(jq -r '.encryption_key' "$DIRECTORIES_CONFIG_FILE")

# Create RunWay and log folders if they don't exist
mkdir -p "$RUNWAY_FOLDER"
mkdir -p "$LOG_FOLDER"

# Start logging
log_message "INFO" "Compression started at $(date +'%Y-%m-%d %H:%M:%S') on $SERVER_NAME"
log_message "DEBUG" "RunWay folder: $RUNWAY_FOLDER"
log_message "DEBUG" "Backup file name: $BACKUP_FILE_NAME"
log_message "DEBUG" "Encryption enabled: $ENCRYPTION_ENABLED"

# Compress and encrypt each directory
for DIR_ENTRY in $DIRECTORIES; do
    DIR=$(echo "$DIR_ENTRY" | jq -r '.path')
    EXCLUDES=$(echo "$DIR_ENTRY" | jq -r '.exclude[]')
    
    BASENAME=$(basename "$DIR")
    ENCRYPTED_FILE="$RUNWAY_FOLDER/${SERVER_NAME}_${BACKUP_FILE_NAME}_${BASENAME}.tar.xz.gpg"
    
    log_message "INFO" "Compressing and encrypting $DIR to $ENCRYPTED_FILE"
    log_message "DEBUG" "Directory path: $DIR"
    log_message "DEBUG" "Excludes: $EXCLUDES"
    
    # Build the exclude options for tar and handle them as relative paths
    EXCLUDE_OPTIONS=()
    for EXCLUDE_DIR in $EXCLUDES; do
        RELATIVE_EXCLUDE_DIR="${EXCLUDE_DIR#/}"
        EXCLUDE_OPTIONS+=(--exclude="$DIR/$RELATIVE_EXCLUDE_DIR")
    done
    
    # Debugging output to check exclude options
    log_message "DEBUG" "Exclude options: ${EXCLUDE_OPTIONS[@]}"
    
    # Compress and encrypt the directory
    if tar -cf - "${EXCLUDE_OPTIONS[@]}" -C "$(dirname "$DIR")" "$BASENAME" | xz | gpg --batch --yes --passphrase "$ENCRYPTION_KEY" -c -o "$ENCRYPTED_FILE"; then
        log_message "INFO" "Successfully compressed and encrypted $DIR"
    else
        log_message "ERROR" "Error compressing and encrypting $DIR"
    fi
done

# Call the cleanup script
log_message "INFO" "Calling cleanup script"
/FilePort/Hangar/Scripts/FilePortCleanUp.sh "$MAIN_CONFIG_FILE" "$LOG_FILE"

# End logging
log_message "INFO" "Compression completed at $(date +'%Y-%m-%d %H:%M:%S') on $SERVER_NAME"
