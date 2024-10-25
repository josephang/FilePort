#!/bin/bash

# Usage: ./FilePortTakeOff.sh [clearance_config_file] [-m main_config_file]
# If no arguments are provided, it defaults to using 'default_clearance_config.json' and 'default_main_config.json' in the default config directory.

# Hardcoded path to the default config directory
DEFAULT_CONFIG_DIR="/FilePort/Hangar/Configs"
DEFAULT_MAIN_CONFIG_FILE="$DEFAULT_CONFIG_DIR/default_main_config.json"
DEFAULT_CLEARANCE_CONFIG_FILE="$DEFAULT_CONFIG_DIR/default_clearance.json"
DEFAULT_SYNC_SCRIPT_PATH="/FilePort/Hangar/Scripts/FilePortPilot.sh"

# Use the provided arguments or fall back to the default config files
CLEARANCE_CONFIG_FILE="${1:-$DEFAULT_CLEARANCE_CONFIG_FILE}"
MAIN_CONFIG_FILE="$DEFAULT_MAIN_CONFIG_FILE"

# Determine the sync script path
if [ -f "$(dirname "$0")/FilePortPilot.sh" ]; then
    SYNC_SCRIPT_PATH="$(dirname "$0")/FilePortPilot.sh"
else
    SYNC_SCRIPT_PATH="$DEFAULT_SYNC_SCRIPT_PATH"
fi

# Function to search for a file in the config directory
search_config_file() {
    local file_name=$1
    find "$DEFAULT_CONFIG_DIR" -type f -name "$file_name" 2>/dev/null | head -n 1
}

# Source the main configuration file
source "$(dirname "$0")/FilePortConfig.sh" "$MAIN_CONFIG_FILE"

# Logging function
log_message() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" >> "$LOG_FOLDER/$LOG_FILE_NAME"
}

# Search for the clearance configuration file if it doesn't exist
if [ ! -f "$CLEARANCE_CONFIG_FILE" ]; then
    CLEARANCE_CONFIG_FILE=$(search_config_file "$(basename "$CLEARANCE_CONFIG_FILE")")
    if [ -z "$CLEARANCE_CONFIG_FILE" ]; then
        log_message "ERROR" "Clearance configuration file not found: $CLEARANCE_CONFIG_FILE"
        exit 1
    fi
fi

# Read the clearance configuration file and extract the settings
REMOTE_USER=$(jq -r '.remote_user' "$CLEARANCE_CONFIG_FILE")
REMOTE_HOST=$(jq -r '.remote_host' "$CLEARANCE_CONFIG_FILE")
PORT=$(jq -r '.port' "$CLEARANCE_CONFIG_FILE")
SSL_CERT_PATH=$(jq -r '.ssl_cert_path' "$CLEARANCE_CONFIG_FILE")

# Read the directories from the clearance configuration file
DIRECTORIES=$(jq -c '.directories[]' "$CLEARANCE_CONFIG_FILE")

for DIR in $DIRECTORIES; do
    LOCAL_DIR=$(echo $DIR | jq -r '.local')
    REMOTE_DIR=$(echo $DIR | jq -r '.remote')
    "$SYNC_SCRIPT_PATH" "$LOCAL_DIR" "$REMOTE_DIR" "$PORT" "$REMOTE_HOST" "$REMOTE_USER" "$SSL_CERT_PATH" "$MAIN_CONFIG_FILE"
    log_message "INFO" "Backup completed from $LOCAL_DIR to $REMOTE_DIR"
done

log_message "INFO" "All backups completed."
