#!/bin/bash

# Hardcoded path to the default config directory
DEFAULT_CONFIG_DIR="/FilePort/Hangar/Configs"

# Path to the sync script
DEFAULT_SYNC_SCRIPT_PATH="/FilePort/Hangar/Scripts/FilePortPilot.sh"

# Use the provided argument as the config file name, or fall back to the default config file
CONFIG_FILE="$DEFAULT_CONFIG_DIR/${1:-default_config.json}"

# Check if FilePortPilot.sh is in the same directory
if [ -f "$(dirname "$0")/FilePortPilot.sh" ]; then
    SYNC_SCRIPT_PATH="$(dirname "$0")/FilePortPilot.sh"
else
    SYNC_SCRIPT_PATH="$DEFAULT_SYNC_SCRIPT_PATH"
fi

# Read the JSON file and extract the settings
REMOTE_USER=$(jq -r '.remote_user' "$CONFIG_FILE")
REMOTE_HOST=$(jq -r '.remote_host' "$CONFIG_FILE")
PORT=$(jq -r '.port' "$CONFIG_FILE")
SSL_CERT_PATH=$(jq -r '.ssl_cert_path' "$CONFIG_FILE")

# Read the directories
DIRECTORIES=$(jq -c '.directories[]' "$CONFIG_FILE")

for DIR in $DIRECTORIES; do
    LOCAL_DIR=$(echo $DIR | jq -r '.local')
    REMOTE_DIR=$(echo $DIR | jq -r '.remote')
    "$SYNC_SCRIPT_PATH" "$LOCAL_DIR" "$REMOTE_DIR" "$PORT" "$REMOTE_HOST" "$REMOTE_USER" "$SSL_CERT_PATH"
done
