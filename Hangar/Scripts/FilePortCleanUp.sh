#!/bin/bash

MAIN_CONFIG_FILE="$1"
LOG_FILE="$2"

# Check if the main configuration file exists
if [ ! -f "$MAIN_CONFIG_FILE" ]; then
    echo "Main configuration file not found: $MAIN_CONFIG_FILE"
    exit 1
fi

# Read the main configuration file
LOG_FOLDER=$(jq -r '.log_folder' "$MAIN_CONFIG_FILE")
LOG_KEEP_DAYS=$(jq -r '.log_keep_days' "$MAIN_CONFIG_FILE")

# Delete log files in the log folder that are older than the specified retention period
find "$LOG_FOLDER" -type f -mtime +"$LOG_KEEP_DAYS" -exec rm -f {} \; -exec echo "Deleted old log file: {}" \; | tee -a "$LOG_FILE"
