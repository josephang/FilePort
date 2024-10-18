#!/bin/bash

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
BACKUP_FOLDER=$(jq -r '.backup_folder' "$MAIN_CONFIG_FILE")
LOG_FOLDER=$(jq -r '.log_folder' "$MAIN_CONFIG_FILE")
BACKUP_KEEP_DAYS=$(jq -r '.backup_keep_days' "$MAIN_CONFIG_FILE")
LOG_KEEP_DAYS=$(jq -r '.log_keep_days' "$MAIN_CONFIG_FILE")

# Read the directories configuration file
DIRECTORIES=($(jq -r '.directories[]' "$DIRECTORIES_CONFIG_FILE"))

# Create backup and log folders if they don't exist
mkdir -p "$BACKUP_FOLDER"
mkdir -p "$LOG_FOLDER"

# Log file with date and time
LOG_FILE="$LOG_FOLDER/compression_${SERVER_NAME}_$(date +'%Y%m%d_%H%M%S').log"

# Start logging
echo "Compression started at $(date +'%Y-%m-%d %H:%M:%S') on $SERVER_NAME" | tee -a "$LOG_FILE"

# Compress each directory with maximum compression using xz
for DIR in "${DIRECTORIES[@]}"; do
    BASENAME=$(basename "$DIR")
    DATE_STR=$(date +'%Y%m%d')
    COMPRESSED_FILE="$BACKUP_FOLDER/${BASENAME}_${SERVER_NAME}_${DATE_STR}.tar.xz"
    echo "Compressing $DIR to $COMPRESSED_FILE" | tee -a "$LOG_FILE"
    
    # Run the tar command to compress the directory
    if tar -cJf "$COMPRESSED_FILE" -C "$(dirname "$DIR")" "$BASENAME" 2>> "$LOG_FILE"; then
        echo "Successfully compressed $DIR" | tee -a "$LOG_FILE"
    else
        echo "Error compressing $DIR" | tee -a "$LOG_FILE"
    fi
done

# Call the cleanup script
"$SCRIPT_DIR/FilePortCleanUp.sh" "$MAIN_CONFIG_FILE" "$LOG_FILE"

# End logging
echo "Compression completed at $(date +'%Y-%m-%d %H:%M:%S') on $SERVER_NAME" | tee -a "$LOG_FILE"
