#!/bin/bash

# Usage: ./FilePortCleanUp.sh main_config_file log_file
# Deletes log files in the log folder that are older than the specified retention period.

MAIN_CONFIG_FILE="$1"
LOG_FILE="$2"

# Source the main configuration file
source "$(dirname "$0")/FilePortConfig.sh" "$MAIN_CONFIG_FILE"

# Logging function
log_message() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" | tee -a "$LOG_FILE"
}

# Ensure the log folder exists
if [ ! -d "$LOG_FOLDER" ]; then
    log_message "ERROR" "Log folder not found: $LOG_FOLDER"
    exit 1
fi

# Log the start of the cleanup process
log_message "INFO" "Starting cleanup process in $LOG_FOLDER, deleting files older than $LOG_KEEP_DAYS days."

# Delete log files in the log folder that are older than the specified retention period
find "$LOG_FOLDER" -type f -mtime +"$LOG_KEEP_DAYS" -exec rm -f {} \; -exec log_message "INFO" "Deleted old log file: {}" \;

# Log the completion of the cleanup process
log_message "INFO" "Cleanup process completed."
