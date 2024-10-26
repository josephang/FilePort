#!/bin/bash

main_config="FilePort/Hangar/Configs/main_config.json"

if [ ! -f "$main_config" ]; then
    echo "Main config file not found. Please configure in GuestServices.sh - Exiting."
    exit 1
fi

if [ $(jq -r '.Flight_Ready' $main_config) == "no" ]; then
    echo "System is not Flight Ready. Please Run ./FlightReady.sh in FilePort/Hangar/Scripts/"
    exit 1
fi

root_dir=$(jq -r '.root_dir' $main_config)

echo "Enter Flight Number (e.g., 123):"
read FlightNumber

# Create directory for the flight number if it doesn't exist
flight_config_dir="$root_dir/FilePort/Hangar/Configs/${FlightNumber}"
mkdir -p "$flight_config_dir"

echo "Do you want compression? (yes/no) [default: no]:"
read compression
compression=${compression:-no}

if [ "$compression" == "yes" ]; then
    compress_config="$flight_config_dir/_${FlightNumber}_comp.json"
    cp "$root_dir/FilePort/Hangar/Configs/FlightPlan_template_comp.json" $compress_config

    echo "Enter target storage file path. Save compressed file to [default: /target/storage/folder]:"
    read compression_folder
    compression_folder=${compression_folder:-/default/compression/folder}
    echo "Enter job name [default: Default-Job]:"
    read job_name
    job_name=${job_name:-Default-Job}
    echo "Enable password encryption? (yes/no) [default: yes]:"
    read encryption_enabled
    encryption_enabled=${encryption_enabled:-yes}
    if [ "$encryption_enabled" == "yes" ]; then
        echo "Enter encryption key [default: extremely_long_encryption_key]:"
        read encryption_key
        encryption_key=${encryption_key:-default_encryption_key}
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

echo "Do you want to upload to remote server? (yes/no) [default: no]:"
read upload
upload=${upload:-no}

if [ "$upload" == "yes" ]; then
    upload_config="$flight_config_dir/_${FlightNumber}_clear.json"
    cp "$root_dir/FilePort/Hangar/Configs/FlightPlan_template_clear.json" $upload_config

    echo "Enter local user [default: default_user]:"
    read local_user
    local_user=${local_user:-default_user}
    echo "Enter SSL certificate path [default: /home/default_user/.ssh/id_rsa]:"
    read ssl_cert_path
    ssl_cert_path=${ssl_cert_path:-/default/path/to/ssl_cert}
    echo "Enter remote user [default: default_remote_user]:"
    read remote_user
    remote_user=${remote_user:-default_remote_user}
    echo "Enter remote host [default: default.remote.host.net]:"
    read remote_host
    remote_host=${remote_host:-default.remote.host}
    echo "Enter port [default: 22]:"
    read port
    port=${port:-22}
    echo "Enter local directory path [default: /default/local/path]:"
    read local_dir
    local_dir=${local_dir:-/default/local/path}
    echo "Enter remote directory path [default: /default/remote/path]:"
    read remote_dir
    remote_dir=${remote_dir:-/default/remote/path}

    jq --arg local_user "$local_user" \
       --arg ssl_cert_path "$ssl_cert_path" \
       --arg remote_user "$remote_user" \
       --arg remote_host "$remote_host" \
       --argjson port "$port" \
       --arg local_dir "$local_dir" \
       --arg remote_dir "$remote_dir" \
       '.local_user = $local_user |
        .ssl_cert_path = $ssl_cert_path |
        .remote_user = $remote_user |
        .remote_host = $remote_host |
        .port = $port |
        .directories[0].local = $local_dir |
        .directories[0].remote = $remote_dir' $upload_config > tmp.$$.json && mv tmp.$$.json $upload_config
fi

flight_plan="$root_dir/FilePort/FlightPlans/FlightPlan-${FlightNumber}.sh"
echo "$root_dir/FilePort/Hangar/Scripts/FilePortATC.sh -m $main_config -c $compress_config -u $upload_config > $root_dir/FilePort/Hangar/Logs/FilePort.log 2>&1" > $flight_plan
chmod +x $flight_plan

echo "Flight plan created: $flight_plan"
