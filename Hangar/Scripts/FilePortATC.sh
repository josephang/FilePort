#!/bin/bash

# Directory paths
SCRIPT_DIR="/FilePort/Hangar/Scripts"
CONFIG_DIR="/FilePort/Hangar/Configs"

# Function to display usage
usage() {
    echo "Usage: $0 [-a] [-c config1.json,config2.json,...]"
    echo "  -a  Process all JSON configuration files in the configs folder"
    echo "  -c  Process specified JSON configuration files (comma-separated)"
    exit 1
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
        echo "Directories configuration file not found: $FULL_PATH"
        continue
    fi
    echo "Processing configuration: $FULL_PATH"
    
    # Call the compression script
    "$SCRIPT_DIR/FilePortCompress.sh" "$FULL_PATH"
done

echo "All configurations processed."
