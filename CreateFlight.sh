#!/bin/bash

# Usage: ./CreateFlight.sh
# This script helps create default directory and clearance JSON files, and generates a flight plan script.

# Default configurations
ROOT_DIR="~/FilePort"
CONFIG_DIR="$ROOT_DIR/Hangar/Configs"
SCRIPT_DIR="$ROOT_DIR/Hangar/Scripts"
DEFAULT_FLIGHT_PLAN_DIR="FlightPlans"
MAIN_CONFIG_FILE="$CONFIG_DIR/main_config.json"

# Function to display usage
usage() {
    echo "Usage: $0"
    exit 1
}

# Function to prompt the user for input with a default value
prompt() {
    local prompt_text=$1
    local default_value=$2
    read -p "$prompt_text [$default_value]: " input
    echo "${input:-$default_value}"
}

# Function to create a directory if it doesn't exist
create_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        if [ $? -ne 0 ]; then
            echo "Error creating directory: $dir"
            exit 1
        fi
        echo "Directory created: $dir"
    else
        echo "Directory already exists: $dir"
    fi
}

# Function to set up the main configuration file
setup_main_config() {
    echo "Setting up main configuration..."
    server_name=$(prompt "Enter the server name" "MyServer")
    log_folder=$(prompt "Enter the log folder path" "/FilePort/Hangar/Logs")
    log_file_name=$(prompt "Enter the log file name" "FilePort.log")
    log_keep_days=$(prompt "Enter the number of days to keep logs" "1095")
    log_level=$(prompt "Enter the log level" "INFO")
    retry_attempts=$(prompt "Enter the number of retry attempts" "3")
    smtp_server=$(prompt "Enter the SMTP server" "smtp.example.com")
    smtp_port=$(prompt "Enter the SMTP port" "587")
    smtp_user=$(prompt "Enter the SMTP user" "user@example.com")
    smtp_password=$(prompt "Enter the SMTP password" "password")
    smtp_from=$(prompt "Enter the SMTP from address" "noreply@example.com")
    smtp_to=$(prompt "Enter the SMTP to addresses (comma-separated)" "admin@example.com,support@example.com")
    mc_setup="yes"

    smtp_to_array=$(echo "$smtp_to" | tr ',' '\n' | sed 's/^/    "/;s/$/"/' | paste -sd, -)

    echo "{" > "$MAIN_CONFIG_FILE"
    echo "  \"server_name\": \"$server_name\"," >> "$MAIN_CONFIG_FILE"
    echo "  \"log_folder\": \"$log_folder\"," >> "$MAIN_CONFIG_FILE"
    echo "  \"log_file_name\": \"$log_file_name\"," >> "$MAIN_CONFIG_FILE"
    echo "  \"log_keep_days\": $log_keep_days," >> "$MAIN_CONFIG_FILE"
    echo "  \"log_level\": \"$log_level\"," >> "$MAIN_CONFIG_FILE"
    echo "  \"retry_attempts\": $retry_attempts," >> "$MAIN_CONFIG_FILE"
    echo "  \"smtp_server\": \"$smtp_server\"," >> "$MAIN_CONFIG_FILE"
    echo "  \"smtp_port\": $smtp_port," >> "$MAIN_CONFIG_FILE"
    echo "  \"smtp_user\": \"$smtp_user\"," >> "$MAIN_CONFIG_FILE"
    echo "  \"smtp_password\": \"$smtp_password\"," >> "$MAIN_CONFIG_FILE"
    echo "  \"smtp_from\": \"$smtp_from\"," >> "$MAIN_CONFIG_FILE"
    echo "  \"smtp_to\": [$smtp_to_array]," >> "$MAIN_CONFIG_FILE"
    echo "  \"mc_setup\": \"$mc_setup\"" >> "$MAIN_CONFIG_FILE"
    echo "}" >> "$MAIN_CONFIG_FILE"
    echo "Main configuration file created: $MAIN_CONFIG_FILE"
}

# Check if the main configuration file exists and if setup is needed
if [ ! -f "$MAIN_CONFIG_FILE" ]; then
    echo "Warning! Main configuration file not found."
    echo "If you are running for the first time or have set up main_config.json already, please fix ROOT_DIR at the beginning of this script."
    echo "Attempting to create main_config.json... ^C to Cancel."
    setup_main_config
else
    mc_setup=$(jq -r '.mc_setup' "$MAIN_CONFIG_FILE")
    if [ "$mc_setup" == "no" ]; then
        echo "Main configuration file found, but is not set up."
        setup_main_config
    else
        echo "Main configuration file found: $MAIN_CONFIG_FILE"
    fi
fi


# Prompt the user for the flight plan number
flight_number=$(prompt "Enter the flight number" "101")

# Prompt the user for the directory to save the configs
config_save_dir=$(prompt "Enter the directory to save the configs (hit enter for default)" "$CONFIG_DIR")

# Create the directory if it doesn't exist
create_directory "$config_save_dir"

# Define the configuration file names based on the flight number
directory_config_file="$config_save_dir/FlightPlan_${flight_number}_DIR.json"
clearance_config_file="$config_save_dir/FlightPlan_${flight_number}_CLEAR.json"

# Prompt the user for entries for the directory config
echo "Creating directory configuration..."
runway_folder=$(prompt "Enter the RunWay folder path (where compressed/encrypted folders will be saved)" "/FilePort/RunWay")
backup_file_name=$(prompt "Enter the backup file name" "FilePort-Default-Backup")
encryption_enabled=$(prompt "Is encryption enabled? (yes/no)" "no")
encryption_key=$(prompt "Enter the encryption key" "your_long_encryption_key_here")

echo "{" > "$directory_config_file"
echo "  \"RunWay_Folder\": \"$runway_folder\"," >> "$directory_config_file"
echo "  \"backup_file_name\": \"$backup_file_name\"," >> "$directory_config_file"
echo "  \"encryption_enabled\": \"$encryption_enabled\"," >> "$directory_config_file"
echo "  \"encryption_key\": \"$encryption_key\"," >> "$directory_config_file"
echo "  \"directories\": [" >> "$directory_config_file"
while true; do
    local_dir=$(prompt "Enter a directory to include" "")
    echo "    {" >> "$directory_config_file"
    echo "      \"path\": \"$local_dir\"," >> "$directory_config_file"
    echo "      \"exclude\": [" >> "$directory_config_file"
    while true; do
        exclusion_dir=$(prompt "Enter an exclusion directory for $local_dir (leave blank to stop)" "")
        if [ -z "$exclusion_dir" ]; then
            break
        fi
        echo "        \"$exclusion_dir\"," >> "$directory_config_file"
    done
    sed -i '$ s/,$//' "$directory_config_file"  # Remove the last comma
    echo "      ]" >> "$directory_config_file"
    echo "    }," >> "$directory_config_file"
    more=$(prompt "Do you want to add another directory? (y/n)" "n")
    if [ "$more" != "y" ]; then
        break
    fi
done
sed -i '$ s/,$//' "$directory_config_file"  # Remove the last comma
echo "  ]" >> "$directory_config_file"
echo "}" >> "$directory_config_file"
echo "Directory configuration file created: $directory_config_file"

# Prompt the user for entries for the clearance config
echo "Creating clearance configuration..."
local_user=$(prompt "Enter the local user" "your_local_user")
ssl_cert_path=$(prompt "Enter the SSL certificate path" "/path/to/your/cert")
remote_user=$(prompt "Enter the remote user" "your_remote_user")
remote_host=$(prompt "Enter the remote host" "your_remote_host")
port=$(prompt "Enter the port" "22")

echo "{" > "$clearance_config_file"
echo "  \"local_user\": \"$local_user\"," >> "$clearance_config_file"
echo "  \"ssl_cert_path\": \"$ssl_cert_path\"," >> "$clearance_config_file"
echo "  \"remote_user\": \"$remote_user\"," >> "$clearance_config_file"
echo "  \"remote_host\": \"$remote_host\"," >> "$clearance_config_file"
echo "  \"port\": $port," >> "$clearance_config_file"
echo "  \"directories\": [" >> "$clearance_config_file"
while true; do
    local_dir=$(prompt "Enter the local directory to sync" "")
    remote_dir=$(prompt "Enter the remote directory to sync to" "")
    echo "    {" >> "$clearance_config_file"
    echo "      \"local\": \"$local_dir\"," >> "$clearance_config_file"
    echo "      \"remote\": \"$remote_dir\"" >> "$clearance_config_file"
    echo "    }," >> "$clearance_config_file"
    more=$(prompt "Do you want to add another directory? (y/n)" "n")
    if [ "$more" != "y" ]; then
        break
    fi
done
sed -i '$ s/,$//' "$clearance_config_file"  # Remove the last comma
echo "  ]" >> "$clearance_config_file"
echo "}" >> "$clearance_config_file"
echo "Clearance configuration file created: $clearance_config_file"

# Prompt the user for the directory to save the flight plans
flight_plan_save_dir=$(prompt "Enter the directory to save the flight plans (hit enter for default)" "$DEFAULT_FLIGHT_PLAN_DIR")

# Create the directory if it doesn't exist
create_directory "$flight_plan_save_dir"

# Create the flight plan script
flight_plan_file="$flight_plan_save_dir/Flight$flight_number.sh"
echo "#!/bin/bash" > "$flight_plan_file"
echo "# Flight$flight_number.sh - Custom backup and sync job" >> "$flight_plan_file"
echo "" >> "$flight_plan_file"
echo "# Call FlightPlan.sh with the configured settings" >> "$flight_plan_file"
echo "$SCRIPT_DIR/FlightPlan.sh \\" >> "$flight_plan_file"
echo "    -d \"$directory_config_file\" \\" >> "$flight_plan_file"
echo "    -c \"$clearance_config_file\" \\" >> "$flight_plan_file"
echo "    -m \"$MAIN_CONFIG_FILE\"" >> "$flight_plan_file"
chmod +x "$flight_plan_file"

echo "Flight plan created: $flight_plan_file"
echo "Directory configuration file: $directory_config_file"
echo "Clearance configuration file: $clearance_config_file"

