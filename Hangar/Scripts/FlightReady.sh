#!/bin/bash

while getopts r: flag
do
    case "${flag}" in
        r) root_dir=${OPTARG};;
    esac
done

main_config="$root_dir/FilePort/Hangar/Configs/main_config.json"

if [ ! -f "$main_config" ]; then
    echo "Main config file not found in FlightReady.sh. Please configure in GuestServices.sh - Exiting."
    exit 1
fi

if [ $(jq -r '.Flight_Ready' $main_config) == "yes" ]; then
    echo "System is already Flight Ready. Run /GuestServices.sh ->"
    exit 1
fi

if [ $(jq -r '.mc_setup' $main_config) == "no" ]; then
    # Read existing values from the JSON file
    existing_root_dir=$(jq -r '.root_dir' $main_config)
    existing_server_name=$(jq -r '.server_name' $main_config)
    existing_retry_attempts=$(jq -r '.retry_attempts' $main_config)
    existing_smtp_server=$(jq -r '.smtp_server' $main_config)
    existing_smtp_port=$(jq -r '.smtp_port' $main_config)
    existing_smtp_user=$(jq -r '.smtp_user' $main_config)
    existing_smtp_password=$(jq -r '.smtp_password' $main_config)
    existing_smtp_from=$(jq -r '.smtp_from' $main_config)
    existing_smtp_to=$(jq -r '.smtp_to | join(",")' $main_config)

    # Prompt user for main config data with existing values as defaults
    echo "Enter the root_dir or folder FilePort is in. (default: $existing_root_dir):"
    read root_dir
    root_dir=${root_dir:-$existing_root_dir}

    echo "Enter your server name (default: $existing_server_name):"
    read server_name
    server_name=${server_name:-$existing_server_name}

    echo "Enter retry attempts (default: $existing_retry_attempts):"
    read retry_attempts
    retry_attempts=${retry_attempts:-$existing_retry_attempts}

    echo "Enter SMTP server (default: $existing_smtp_server):"
    read smtp_server
    smtp_server=${smtp_server:-$existing_smtp_server}

    echo "Enter SMTP port (default: $existing_smtp_port):"
    read smtp_port
    smtp_port=${smtp_port:-$existing_smtp_port}

    echo "Enter SMTP user (default: $existing_smtp_user):"
    read smtp_user
    smtp_user=${smtp_user:-$existing_smtp_user}

    echo "Enter SMTP password (default: $existing_smtp_password):"
    read smtp_password
    smtp_password=${smtp_password:-$existing_smtp_password}

    echo "Enter SMTP from address (default: $existing_smtp_from):"
    read smtp_from
    smtp_from=${smtp_from:-$existing_smtp_from}

    echo "Enter SMTP to addresses (comma-separated, default: $existing_smtp_to):"
    read smtp_to
    smtp_to=${smtp_to:-$existing_smtp_to}

    # Setup main config with user-provided data or existing values
    jq --arg root_dir "$root_dir" \
       --arg server_name "$server_name" \
       --argjson retry_attempts "$retry_attempts" \
       --arg smtp_server "$smtp_server" \
       --argjson smtp_port "$smtp_port" \
       --arg smtp_user "$smtp_user" \
       --arg smtp_password "$smtp_password" \
       --arg smtp_from "$smtp_from" \
       --argjson smtp_to "$(echo $smtp_to | jq -R 'split(",")')" \
       '.root_dir = $root_dir |
        .server_name = $server_name |
        .retry_attempts = $retry_attempts |
        .smtp_server = $smtp_server |
        .smtp_port = $smtp_port |
        .smtp_user = $smtp_user |
        .smtp_password = $smtp_password |
        .smtp_from = $smtp_from |
        .smtp_to = $smtp_to |
        .mc_setup = "yes"' $main_config > tmp.$$.json && mv tmp.$$.json $main_config
fi

# Check scripts and configs
scripts=("FilePortATC.sh" "FilePortCompress.sh" "FilePortUpload.sh")
configs=("FlightPlan_template_comp.json" "FlightPlan_template_clear.json" "main_config.json")

for script in "${scripts[@]}"; do
    if [ ! -f "$root_dir/FilePort/Hangar/Scripts/$script" ]; then
        echo "Missing script: $script"
        exit 1
    fi
done

for config in "${configs[@]}"; do
    if [ ! -f "$root_dir/FilePort/Hangar/Configs/$config" ]; then
        echo "Missing config: $config"
        exit 1
    fi
done

# Check for dependencies
dependencies=("jq" "xz" "mail" "rsync" "openssl" "cron")
for dep in "${dependencies[@]}"; do
    if command -v $dep &> /dev/null; then
        echo "$dep is installed"
    else
        echo "$dep is not installed"
    fi
done

jq '.Flight_Ready = "yes"' $main_config > tmp.$$.json && mv tmp.$$.json $main_config
echo "System is Flight Ready. Run /GuestServices.sh ->"
