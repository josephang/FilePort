#!/bin/bash

# Set the root directory variable at the top for easy access
root_dir="/path/to/FilePort"

# Define the main configuration file path
main_config="$root_dir/FilePort/Hangar/Configs/main_config.json"

# Check if the main configuration file exists
if [ ! -f "$main_config" ]; then
    echo "Main config file not found. Please configure in GuestServices.sh - Exiting."
    exit 1
fi

# Check if the system is Flight Ready
if [ $(jq -r '.Flight_Ready' $main_config) == "no" ]; then
    echo "System is not Flight Ready. Running FlightReady.sh..."
    bash "$root_dir/FilePort/Hangar/Scripts/FlightReady.sh" -r "$root_dir"
fi

# Extract the root directory from the main configuration file
root_dir=$(jq -r '.root_dir' $main_config)

# Prompt the user for the flight number
echo "Enter Flight Number (e.g., 123):"
read FlightNumber

# Create a directory for the flight number if it doesn't exist
flight_config_dir="$root_dir/FilePort/Hangar/Configs/${FlightNumber}"
mkdir -p "$flight_config_dir"

# Prompt the user for compression settings
echo "Do you want compression? (yes/no) [default: no]:"
read compression
compression=${compression:-no}

if [ "$compression" == "yes" ]; then
    compress_config="$flight_config_dir/FlightPlan_${FlightNumber}_comp.json"
    cp "$root_dir/FilePort/Hangar/Configs/FlightPlan_template_comp.json" $compress_config

    # Read existing values from the JSON file
    existing_compression_folder=$(jq -r '.compression_Folder' $compress_config)
    existing_job_name=$(jq -r '.job_name' $compress_config)
    existing_encryption_enabled=$(jq -r '.encryption_enabled' $compress_config)
    existing_encryption_key=$(jq -r '.encryption_key' $compress_config)

    # Prompt user for compression settings with existing values as defaults
    echo "Enter target storage file path. Save compressed file to [default: $existing_compression_folder]:"
    read compression_folder
    compression_folder=${compression_folder:-$existing_compression_folder}
    echo "Enter job name [default: $existing_job_name]:"
    read job_name
    job_name=${job_name:-$existing_job_name}
    echo "Enable password encryption? (yes/no) [default: $existing_encryption_enabled]:"
    read encryption_enabled
    encryption_enabled=${encryption_enabled:-$existing_encryption_enabled}
    if [ "$encryption_enabled" == "yes" ]; then
        echo "Enter encryption key [default: $existing_encryption_key]:"
        read encryption_key
        encryption_key=${encryption_key:-$existing_encryption_key}
    else
        encryption_key=""
    fi

    directories=()
    while true; do
        echo "Enter directory path to compress [default: /default/path1]:"
        read dir_path
        dir_path=${dir_path:-/default/path1}
        echo "Enter directories to exclude (Comma-Separated) as a relative path [default: /default/exclude1]:"
        read exclude_dirs
        exclude_dirs=${exclude_dirs:-/default/exclude1}
        directories+=("{\"path\":\"$dir_path\",\"exclude\":[$(echo $exclude_dirs | jq -R 'split(",") | map("\"" + . + "\"") | join(",")')]}")

        echo "Do you want to add another directory? (yes/no) [default: no]:"
        read add_another
        add_another=${add_another:-no}
        if [ "$add_another" != "yes" ]; then
            break
        fi
    done

    directories_json=$(printf '%s\n' "${directories[@]}" | jq -s '.')

    jq --arg compression_folder "$compression_folder" \
       --arg job_name "$job_name" \
       --arg encryption_enabled "$encryption_enabled" \
       --arg encryption_key "$encryption_key" \
       --argjson directories "$directories_json" \
       '.compression_Folder = $compression_folder |
        .job_name = $job_name |
        .encryption_enabled = $encryption_enabled |
        .encryption_key = $encryption_key |
        .directories = $directories' $compress_config > tmp.$$.json && mv tmp.$$.json $compress_config
fi

# Prompt the user for upload settings
echo "Do you want to upload to remote server? (yes/no) [default: no]:"
read upload
upload=${upload:-no}

if [ "$upload" == "yes" ]; then
    upload_config="$flight_config_dir/FlightPlan_${FlightNumber}_clear.json"
    cp "$root_dir/FilePort/Hangar/Configs/FlightPlan_template_clear.json" $upload_config

    # Read existing values from the JSON file
    existing_local_user=$(jq -r '.local_user' $upload_config)
    existing_ssl_cert_path=$(jq -r '.ssl_cert_path' $upload_config)
    existing_remote_user=$(jq -r '.remote_user' $upload_config)
    existing_remote_host=$(jq -r '.remote_host' $upload_config)
    existing_port=$(jq -r '.port' $upload_config)
    existing_local_dir=$(jq -r '.directories[0].local' $upload_config)
    existing_remote_dir=$(jq -r '.directories[0].remote' $upload_config)

    # Prompt user for upload settings with existing values as defaults
    echo "Enter local user [default: $existing_local_user]:"
    read local_user
    local_user=${local_user:-$existing_local_user}
    echo "Enter SSL certificate path [default: $existing_ssl_cert_path]:"
    read ssl_cert_path
    ssl_cert_path=${ssl_cert_path:-$existing_ssl_cert_path}
    echo "Enter remote user [default: $existing_remote_user]:"
    read remote_user
    remote_user=${remote_user:-$existing_remote_user}
    echo "Enter remote host [default: $existing_remote_host]:"
    read remote_host
    remote_host=${remote_host:-$existing_remote_host}
    echo "Enter port [default: $existing_port]:"
    read port
    port=${port:-$existing_port}
    echo "Enter bandwidth limit in KB/s (e.g., 5000) [default: none]:"
    read bwlimit
    bwlimit=${bwlimit:-0}
    echo "Enter local directory path [default: $existing_local_dir]:"
    read local_dir
    local_dir=${local_dir:-$existing_local_dir}
    echo "Enter remote directory path [default: $existing_remote_dir]:"
    read remote_dir
    remote_dir=${remote_dir:-$existing_remote_dir}

    jq --arg local_user "$local_user" \
       --arg ssl_cert_path "$ssl_cert_path" \
       --arg remote_user "$remote_user" \
       --arg remote_host "$remote_host" \
       --argjson port "$port" \
       --argjson bwlimit "$bwlimit" \
       --arg local_dir "$local_dir" \
       --arg remote_dir "$remote_dir" \
       '.local_user = $local_user |
        .ssl_cert_path = $ssl_cert_path |
        .remote_user = $remote_user |
        .remote_host = $remote_host |
        .port = $port |
        .bwlimit = $bwlimit |
        .directories[0].local = $local_dir |
        .directories[0].remote = $remote_dir' $upload_config > tmp.$$.json && mv tmp.$$.json $upload_config
fi

# Create directory for the flight plan if it doesn't exist
flight_plan_dir="$root_dir/FilePort/FlightPlans/${FlightNumber}"
mkdir -p "$flight_plan_dir"

# Create the flight plan script
flight_plan="$flight_plan_dir/FlightPlan-${FlightNumber}.sh"
echo "$root_dir/FilePort/Hangar/Scripts/FilePortATC.sh -m $main_config -c $compress_config -u $upload_config > $root_dir/FilePort/Hangar/Logs/FilePort.log 2>&1" > $flight_plan
chmod +x $flight_plan

# Notify the user that the flight plan has been created
echo "Flight plan created: $flight_plan"
