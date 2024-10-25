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

# Read the directories configuration file
RUNWAY_FOLDER=$(jq -r '.RunWay_Folder' "$DIRECTORIES_CONFIG_FILE")
BACKUP_FILE_NAME=$(jq -r '.backup_file_name' "$DIRECTORIES_CONFIG_FILE")
DIRECTORIES=($(jq -r '.directories[]' "$DIRECTORIES_CONFIG_FILE"))
EXCLUDE=($(jq -r '.exclude[]' "$DIRECTORIES_CONFIG_FILE"))
ENCRYPTION_ENABLED=$(jq -r '.encryption_enabled' "$DIRECTORIES_CONFIG_FILE")
ENCRYPTION_KEY=$(jq -r '.encryption_key' "$DIRECTORIES_CONFIG_FILE")

# Create RunWay and log folders if they don't exist
mkdir -p "$RUNWAY_FOLDER"
mkdir -p "$LOG_FOLDER"

# Log file with date and time
LOG_FILE="$LOG_FOLDER/${LOG_FILE_NAME}_${SERVER_NAME}_$(date +'%Y%m%d_%H%M%S').log"

# Start logging
echo "Compression started at $(date +'%Y-%m-%d %H:%M:%S') on $SERVER_NAME" | tee "$LOG_FILE"

# Compress and encrypt each directory
for DIR in "${DIRECTORIES[@]}"; do
    BASENAME=$(basename "$DIR")
    COMPRESSED_FILE="$RUNWAY_FOLDER/${SERVER_NAME}_${BACKUP_FILE_NAME}_${BASENAME}.tar.xz"
    ENCRYPTED_FILE="${COMPRESSED_FILE}.gpg"
    
    echo "Compressing and encrypting $DIR to $ENCRYPTED_FILE" | tee -a "$LOG_FILE"
    
    # Build the exclude options for tar and handle them as relative paths
    EXCLUDE_OPTIONS=()
    for EXCLUDE_DIR in "${EXCLUDE[@]}"; do
        RELATIVE_EXCLUDE_DIR="${EXCLUDE_DIR#/}"
        EXCLUDE_OPTIONS+=(--exclude="$RELATIVE_EXCLUDE_DIR")
    done
    
    # Debugging output to check exclude options
    echo "Exclude options: ${EXCLUDE_OPTIONS[@]}" | tee -a "$LOG_FILE"
    
    # Compress and encrypt the directory
    if tar -cf - "${EXCLUDE_OPTIONS[@]}" -C "$(dirname "$DIR")" "$BASENAME" | xz | gpg --batch --yes --passphrase "$ENCRYPTION_KEY" -c -o "$ENCRYPTED_FILE"; then
        echo "Successfully compressed and encrypted $DIR" | tee -a "$LOG_FILE"
    else
        echo "Error compressing and encrypting $DIR" | tee -a "$LOG_FILE"
    fi
done

# Call the cleanup script
/FilePort/Hangar/Scripts/FilePortCleanUp.sh "$MAIN_CONFIG_FILE" "$LOG_FILE"

# End logging
echo "Compression completed at $(date +'%Y-%m-%d %H:%M:%S') on $SERVER_NAME" | tee -a "$LOG_FILE"
