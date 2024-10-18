FilePortATC.sh

Overview

FilePortATC.sh is a driver script that automates the process of running compression and cleanup scripts with different JSON configurations. The script scans the configs folder for all JSON files and allows specifying which config or configs to use via command line arguments.

Usage

Command Line Arguments

- -a: Process all JSON configuration files in the configs folder.
- -c: Process specified JSON configuration files (comma-separated).

Examples

1. Process all JSON configuration files:

    ./FilePortATC.sh -a

2. Process specific JSON configuration files:

    ./FilePortATC.sh -c directories_config1.json,directories_config2.json

Configuration Files

Main Configuration File

The main JSON configuration file (main_config.json) should include the following fields:

{
    "server_name": "ServerName",
    "backup_folder": "/FilePort/RunWay",
    "log_folder": "/FilePort/Hangar/Logs",
    "backup_keep_days": 2,
    "log_keep_days": 30
}

- server_name: The name of the server.
- backup_folder: The directory where compressed files will be stored.
- log_folder: The directory where log files will be stored.
- backup_keep_days: The number of days to keep backup files.
- log_keep_days: The number of days to keep log files.

Directories Configuration File

The directories JSON configuration file should include the following field:

{
    "directories": [
        "/service",
        "/usr",
        "/home",
        "/etc",
        "/var",
        "/opt",
        "/srv"
    ]
}

- directories: A list of directories to be compressed.

Scripts

FilePortCompress.sh

This script compresses the specified directories and logs the process.

Usage

./FilePortCompress.sh <directories_config_file.json>

FilePortCleanUp.sh

This script cleans up old backup and log files based on the retention periods specified in the main JSON configuration file.

Usage

./FilePortCleanUp.sh <main_config_file.json> <log_file>

FilePortATC.sh

This driver script automates the process of running the compression and cleanup scripts with different JSON configurations.

Usage

./FilePortATC.sh [-a] [-c directories_config1.json,directories_config2.json,...]

Example JSON Configuration Files

Main Configuration File (main_config.json)

{
    "server_name": "ServerName",
    "backup_folder": "/FilePort/RunWay",
    "log_folder": "/FilePort/Hangar/Logs",
    "backup_keep_days": 2,
    "log_keep_days": 30
}

Directories Configuration File (directories_config1.json)

{
    "directories": [
        "/service",
        "/usr",
        "/home"
    ]
}

Directories Configuration File (directories_config2.json)

{
    "directories": [
        "/etc",
        "/var",
        "/opt",
        "/srv"
    ]
}

Example Script to Call the Driver Script

Flight101.sh

This script calls the driver script with the default_directories.json configuration file.

#!/bin/bash

# Call the driver script with the default directories JSON configuration file
/FilePort/Hangar/Scripts/FilePortATC.sh -c default_directories.json

Notes

- Ensure that jq is installed on your system to parse the JSON configuration files.
- Make sure the scripts are executable:

    chmod +x /FilePort/Hangar/Scripts/FilePortCompress.sh
    chmod +x /FilePort/Hangar/Scripts/FilePortCleanUp.sh
    chmod +x /FilePort/Hangar/Configs/FilePortATC.sh
    chmod +x /FilePort/Hangar/Configs/Flight101.sh

- Run the driver script with the appropriate command line arguments to process the configurations.
