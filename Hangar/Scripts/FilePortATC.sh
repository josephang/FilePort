#!/bin/bash

# Usage: ./FilePortATC.sh [-a] [-c config1.json,config2.json,...]
#  -a  Process all JSON configuration files in the configs folder
#  -c  Process specified JSON configuration files (comma-separated)

# Directory paths
SCRIPT_DIR="/FilePort/Hangar/Scripts"
CONFIG_DIR="/FilePort/Hangar/Configs"
MAIN_CONFIG_FILE="/FilePort/Hangar/Configs/main_config.json"

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq to proceed."
    exit 1
fi

# Check if the main configuration file exists
if [ ! -f "$MAIN_CONFIG_FILE" ]; then
    echo "Main configuration file not found: $MAIN_CONFIG_FILE"
    exit 1
fi

# Read the main configuration file
LOG_FOLDER=$(jq -r '.log_folder' "$MAIN_CONFIG_FILE")
LOG_FILE_NAME=$(jq -r '.log_file_name' "$MAIN_CONFIG_FILE")
LOG_FILE="$LOG_FOLDER/$LOG_FILE_NAME"

# Function to display usage
usage() {
    echo "Usage: $0 [-a] [-c config1.json,config2.json,...]"
    echo "  -a  Process all JSON configuration files in the configs folder"
    echo "  -c  Process specified JSON configuration files (comma-separated)"
    exit 1
}

# Logging function
log_message() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" >> "$LOG_FILE"
}

# Parse command line arguments
PROCESS_ALL=false
CONFIG_FILES=()

while getopts "ac:" opt; do
    case $opt in
        a)
            PROCESS_ALL=true
            ;;
        c)
            IFS=',' read -r -a CONFIG_FILES <<< "$OPTARG"
            ;;
        *)
            usage
            ;;
    esac
done

# If no arguments are provided, display usage
if [ "$#" -eq 0 ]; then
    usage
fi

# If processing all JSON files, scan the configs folder for all JSON files
if [ "$PROCESS_ALL" = true ]; then
    CONFIG_FILES=($(find "$CONFIG_DIR" -type f -name "directories_config*.json"))
fi

# Loop through each configuration file and call the scripts
for CONFIG_FILE in "${CONFIG_FILES[@]}"; do
    FULL_PATH="$CONFIG_DIR/$CONFIG_FILE"
    if [ ! -f "$FULL_PATH" ]; then
        log_message "ERROR" "Directories configuration file not found: $FULL_PATH"
        continue
    fi
    log_message "INFO" "Processing configuration: $FULL_PATH"

    # Call the compression script
    "$SCRIPT_DIR/FilePortCompress.sh" "$FULL_PATH"
    log_message "INFO" "Completed processing configuration: $FULL_PATH"
done

log_message "INFO" "All configurations processed."
