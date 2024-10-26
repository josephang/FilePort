#!/bin/bash

main_config="FilePort/Hangar/Configs/main_config.json"

if [ ! -f "$main_config" ]; then
    echo "Main config file not found. Exiting."
    exit 1
fi

if [ $(jq -r '.Flight_Ready' $main_config) == "yes" ]; then
    echo "System is already Flight Ready. Exiting."
    exit 1
fi

if [ $(jq -r '.mc_setup' $main_config) == "no" ]; then
    # Prompt user for main config data
    echo "Enter root directory:"
    read root_dir
    echo "Enter server name:"
    read server_name
    echo "Enter log file path:"
    read log_file_path
    echo "Enter log level (e.g., INFO, DEBUG):"
    read log_level
    echo "Enter retry attempts:"
    read retry_attempts
    echo "Enter SMTP server:"
    read smtp_server
    echo "Enter SMTP port:"
    read smtp_port
    echo "Enter SMTP user:"
    read smtp_user
    echo "Enter SMTP password:"
    read smtp_password
    echo "Enter SMTP from address:"
    read smtp_from
    echo "Enter SMTP to addresses (comma-separated):"
    read smtp_to

    # Setup main config with user-provided data
    jq --arg root_dir "$root_dir" \
       --arg server_name "$server_name" \
       --arg log_file_path "$log_file_path" \
       --arg log_level "$log_level" \
       --argjson retry_attempts "$retry_attempts" \
       --arg smtp_server "$smtp_server" \
       --argjson smtp_port "$smtp_port" \
       --arg smtp_user "$smtp_user" \
       --arg smtp_password "$smtp_password" \
       --arg smtp_from "$smtp_from" \
       --argjson smtp_to "$(echo $smtp_to | jq -R 'split(",")')" \
       '.root_dir = $root_dir |
        .server_name = $server_name |
        .log_file_path = $log_file_path |
        .log_level = $log_level |
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
root_dir=$(jq -r '.root_dir' $main_config)
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
dependencies=("jq" "xz" "mail" "rsync" "openssl")
for dep in "${dependencies[@]}"; do
    if command -v $dep &> /dev/null; then
        echo "$dep is installed"
    else
        echo "$dep is not installed"
    fi
done

jq '.Flight_Ready = "yes"' $main_config > tmp.$$.json && mv tmp.$$.json $main_config
echo "System is Flight Ready"
