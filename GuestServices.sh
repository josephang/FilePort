#!/bin/bash

main_config="FilePort/Hangar/Configs/main_config.json"

if [ ! -f "$main_config" ]; then
    echo "Main config file not found. Exiting."
    exit 1
fi

if [ $(jq -r '.Flight_Ready' $main_config) == "no" ]; then
    echo "System is not Flight Ready"
    exit 1
fi

root_dir=$(jq -r '.root_dir' $main_config)

echo "Enter Flight Number:"
read FlightNumber

echo "Do you want compression? (yes/no)"
read compression

if [ "$compression" == "yes" ]; then
    compress_config="$root_dir/FilePort/Hangar/Configs/FlightPlan_${FlightNumber}_comp.json"
    cp "$root_dir/FilePort/Hangar/Configs/FlightPlan_template_comp.json" $compress_config

    echo "Enter compression folder path:"
    read compression_folder
    echo "Enter job name:"
    read job_name
    echo "Enable encryption? (yes/no):"
    read encryption_enabled
    if [ "$encryption_enabled" == "yes" ]; then
        echo "Enter encryption key:"
        read encryption_key
    else
        encryption_key=""
    fi

    directories=()
    while true; do
        echo "Enter directory path to compress:"
        read dir_path
        echo "Enter directories to exclude (comma-separated):"
        read exclude_dirs
        directories+=("{\"path\":\"$dir_path\",\"exclude\":[$(echo $exclude_dirs | jq -R 'split(",") | map("\"" + . + "\"") | join(",")')]}")
        
        echo "Do you want to add another directory? (yes/no)"
        read add_another
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

echo "Do you want to upload to remote server? (yes/no)"
read upload

if [ "$upload" == "yes" ]; then
    upload_config="$root_dir/FilePort/Hangar/Configs/FlightPlan_${FlightNumber}_uplo.json"
    cp "$root_dir/FilePort/Hangar/Configs/FlightPlan_template_clear.json" $upload_config

    echo "Enter local user:"
    read local_user
    echo "Enter SSL certificate path:"
    read ssl_cert_path
    echo "Enter remote user:"
    read remote_user
    echo "Enter remote host:"
    read remote_host
    echo "Enter port:"
    read port
    echo "Enter local directory path:"
    read local_dir
    echo "Enter remote directory path:"
    read remote_dir

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
echo "$root_dir/FilePort/Hangar/Scripts/FilePortATC.sh -m $main_config -c $compress_config -u $upload_config" > $flight_plan
chmod +x $flight_plan

echo "Flight plan created: $flight_plan"
