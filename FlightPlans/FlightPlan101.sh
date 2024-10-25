#!/bin/bash

# Flight101.sh - Example script to call FlightPlan.sh with default command line arguments
# This script demonstrates how to use FlightPlan.sh to create custom backup and sync jobs (flights).

# Default configurations
DEFAULT_DIRECTORY_CONFIG="default_directory.json"
DEFAULT_CLEARANCE_CONFIG="default_clearance.json"
DEFAULT_MAIN_CONFIG_FILE="/FilePort/Hangar/Configs/default_main_config.json"
DEFAULT_EMAIL_ADDRESSES="admin@example.com,support@example.com"

# Usage: ./Flight101.sh [-d directory_config_file] [-c clearance_config_file] [-m main_config_file] [-e email1,email2,...] [-C] [-R] [-E]
#  -d  Specify the directory configuration file (optional)
#  -c  Specify the clearance configuration file (optional)
#  -m  Specify the main configuration file (optional)
#  -e  Specify email addresses for notifications (comma-separated, optional)
#  -C  Disable compression
#  -R  Disable remote rsync
#  -E  Disable email notifications

# Example usage:
# ./Flight101.sh -d /path/to/directory_config.json -c /path/to/clearance_config.json -m /path/to/main_config.json -e email1@example.com,email2@example.com -C -R -E

# Call FlightPlan.sh with default command line arguments
/FilePort/Hangar/Scripts/FlightPlan.sh \
    -d "$DEFAULT_DIRECTORY_CONFIG" \
    -c "$DEFAULT_CLEARANCE_CONFIG" \
    -m "$DEFAULT_MAIN_CONFIG_FILE" \
    -e "$DEFAULT_EMAIL_ADDRESSES"

# Explanation of command line arguments:
# -d: Specifies the directory configuration file. This file contains the directories to be compressed.
# -c: Specifies the clearance configuration file. This file contains the directories to be synced.
# -m: Specifies the main configuration file. This file contains global settings such as log folder, SMTP settings, etc.
# -e: Specifies email addresses for notifications. Multiple email addresses can be provided, separated by commas.
# -C: Disables compression. If this flag is set, the compression step will be skipped.
# -R: Disables remote rsync. If this flag is set, the remote rsync step will be skipped.
# -E: Disables email notifications. If this flag is set, email notifications will not be sent.

# Customizing your flight:
# To create a custom backup and sync job, modify the command line arguments as needed.
# For example, to use a different directory configuration file and disable compression:
# /FilePort/Hangar/Scripts/FlightPlan.sh -d /path/to/custom_directory_config.json -C

# To specify multiple directory configuration files, separate them with commas:
# /FilePort/Hangar/Scripts/FlightPlan.sh -d /path/to/dir_config1.json,/path/to/dir_config2.json

# To specify multiple email addresses for notifications, separate them with commas:
# /FilePort/Hangar/Scripts/FlightPlan.sh -e email1@example.com,email2@example.com

# After configuring your flight, you can set this script to be run by cron for automated backups and syncs.
