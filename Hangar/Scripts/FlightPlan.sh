#!/bin/bash

# Usage: ./FlightPlan.sh [-d directory_config_file] [-c clearance_config_file] [-m main_config_file] [-e email1,email2,...] [-C] [-R] [-E]
# This script drives the entire FilePort process based on user-defined options.

# Default configurations
ROOT_DIR="/FilePort/Hangar"
CONFIG_DIR="$ROOT_DIR/Configs"
LOG_DIR="$ROOT_DIR/Logs"
SCRIPT_DIR="$ROOT_DIR/Scripts"
DEFAULT_DIRECTORY_CONFIG="$CONFIG_DIR/default_directory.json"
DEFAULT_CLEARANCE_CONFIG="$CONFIG_DIR/default_clearance.json"
MAIN_CONFIG_FILE="$CONFIG_DIR/default_main_config.json"

# User options
COMPRESSION_ENABLED=true
REMOTE_RSYNC_ENABLED=true
EMAIL_NOTIFICATION_ENABLED=true
EMAIL_ADDRESSES=()

# Email settings
EMAIL_SUBJECT="FilePort Flight Plan Completed"
EMAIL_BODY="The FilePort flight plan has been completed successfully. Please find the log attached."

# Function to display usage
usage() {
    echo "Usage: $0 [-d directory_config_file] [-c clearance_config_file] [-m main_config_file] [-e email1,email2,...] [-C] [-R] [-E]"
    echo "  -d  Specify the directory configuration file (optional)"
    echo "  -c  Specify the clearance configuration file (optional)"
    echo "  -m  Specify the main configuration file (optional)"
    echo "  -e  Specify email addresses for notifications (comma-separated, optional)"
    echo "  -C  Disable compression"
    echo "  -R  Disable remote rsync"
    echo "  -E  Disable email notifications"
    exit 1
}

# Parse command line arguments
while getopts "d:c:m:e:CRE" opt; do
    case $opt in
        d)
            DEFAULT_DIRECTORY_CONFIG="$OPTARG"
            ;;
        c)
            DEFAULT_CLEARANCE_CONFIG="$OPTARG"
            ;;
        m)
            MAIN_CONFIG_FILE="$OPTARG"
            ;;
        e)
            IFS=',' read -r -a EMAIL_ADDRESSES <<< "$OPTARG"
            EMAIL_NOTIFICATION_ENABLED=true
            ;;
        C)
            COMPRESSION_ENABLED=false
            ;;
        R)
            REMOTE_RSYNC_ENABLED=false
            ;;
        E)
            EMAIL_NOTIFICATION_ENABLED=false
            ;;
        *)
            usage
            ;;
    esac
done

# Source the main configuration file
source "$SCRIPT_DIR/FilePortConfig.sh" "$MAIN_CONFIG_FILE"

# Update email subject with server name
EMAIL_SUBJECT="FilePort Flight Plan Completed on $SERVER_NAME"

# Logging function
log_message() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" >> "$LOG_FOLDER/$LOG_FILE_NAME"
}

# Function to search for a file in the config directory and its subdirectories
search_config_file() {
    local file_name=$1
    find "$CONFIG_DIR" -type f -name "$file_name" 2>/dev/null | head -n 1
}

# Function to send an email via SMTP
send_email() {
    local subject=$1
    local body=$2
    local attachment=$3

    # Create the email content
    {
        echo "From: $SMTP_FROM"
        echo "To: $(IFS=,; echo "${SMTP_TO[*]}")"
        echo "Subject: $subject"
        echo "MIME-Version: 1.0"
        echo "Content-Type: multipart/mixed; boundary=\"boundary\""
        echo
        echo "--boundary"
        echo "Content-Type: text/plain"
        echo
        echo "$body"
        echo
        echo "--boundary"
        echo "Content-Type: text/plain"
        echo "Content-Disposition: attachment; filename=$(basename "$attachment")"
        echo
        cat "$attachment"
        echo
        echo "--boundary--"
    } | sendmail -t -oi -f "$SMTP_FROM" -S "$SMTP_SERVER:$SMTP_PORT" -au"$SMTP_USER" -ap"$SMTP_PASSWORD"
}

# Find the directory configuration file
if [ ! -f "$DEFAULT_DIRECTORY_CONFIG" ]; then
    DIRECTORY_CONFIG_FILE=$(search_config_file "$(basename "$DEFAULT_DIRECTORY_CONFIG")")
    if [ -z "$DIRECTORY_CONFIG_FILE" ]; then
        log_message "ERROR" "Directory configuration file not found: $DEFAULT_DIRECTORY_CONFIG"
        exit 1
    fi
else
    DIRECTORY_CONFIG_FILE="$DEFAULT_DIRECTORY_CONFIG"
fi

# Find the clearance configuration file
if [ ! -f "$DEFAULT_CLEARANCE_CONFIG" ]; then
    CLEARANCE_CONFIG_FILE=$(search_config_file "$(basename "$DEFAULT_CLEARANCE_CONFIG")")
    if [ -z "$CLEARANCE_CONFIG_FILE" ]; then
        log_message "ERROR" "Clearance configuration file not found: $DEFAULT_CLEARANCE_CONFIG"
        exit 1
    fi
else
    CLEARANCE_CONFIG_FILE="$DEFAULT_CLEARANCE_CONFIG"
fi

# Run the compression script if enabled
if [ "$COMPRESSION_ENABLED" = true ]; then
    log_message "INFO" "Starting compression process."
    "$SCRIPT_DIR/FilePortCompress.sh" "$DIRECTORY_CONFIG_FILE" "$MAIN_CONFIG_FILE"
    log_message "INFO" "Compression process completed."
fi

# Run the remote rsync script if enabled
if [ "$REMOTE_RSYNC_ENABLED" = true ]; then
    log_message "INFO" "Starting remote rsync process."
    "$SCRIPT_DIR/FilePortTakeOff.sh" "$CLEARANCE_CONFIG_FILE" "$MAIN_CONFIG_FILE"
    log_message "INFO" "Remote rsync process completed."
fi

# Run the cleanup script
log_message "INFO" "Starting cleanup process."
"$SCRIPT_DIR/FilePortCleanUp.sh" "$MAIN_CONFIG_FILE" "$LOG_FOLDER/$LOG_FILE_NAME"
log_message "INFO" "Cleanup process completed."

# Send email notification if enabled
if [ "$EMAIL_NOTIFICATION_ENABLED" = true ]; then
    log_message "INFO" "Sending email notification."
    send_email "$EMAIL_SUBJECT" "$EMAIL_BODY" "$LOG_FOLDER/$LOG_FILE_NAME"
    log_message "INFO" "Email notification sent."
fi

log_message "INFO" "Flight plan execution completed."
