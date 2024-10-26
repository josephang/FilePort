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
    # Prompt user for main config data with default options
    echo "Enter root directory of FilePort (default: /default/root/dir):"
    read root_dir
    root_dir=${root_dir:-/default/root/dir}

    echo "Enter server name (default: default_server):"
    read server_name
    server_name=${server_name:-default_server}

    echo "Enter retry attempts (default: 3):"
    read retry_attempts
    retry_attempts=${retry_attempts:-3}

    echo "Enter SMTP server (default: smtp.default.com):"
    read smtp_server
    smtp_server=${smtp_server:-smtp.default.com}

    echo "Enter SMTP port (default: 587):"
    read smtp_port
    smtp_port=${smtp_port:-587}

    echo "Enter SMTP user (default: apikey):"
    read smtp_user
    smtp_user=${smtp_user:-default_user}

    echo "Enter SMTP password (default: secret):"
    read smtp_password
    smtp_password=${smtp_password:-default_password}

    echo "Enter SMTP from address (default: default@default.com):"
    read smtp_from
    smtp_from=${smtp_from:-default@default.com}

    echo "Enter SMTP to addresses (comma-separated, default: default@default.com):"
    read smtp_to
    smtp_to=${smtp_to:-default@default.com}

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
