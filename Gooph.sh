#!/bin/bash

RED="$(printf '\033[31m')"  
GREEN="$(printf '\033[32m')"  
ORANGE="$(printf '\033[33m')"  
BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  
CYAN="$(printf '\033[36m')"  
WHITE="$(printf '\033[37m')" 
BLACK="$(printf '\033[30m')"

install_packages() {
    echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing required packages..."

    if [[ -d "/data/data/com.termux/files/home" ]]; then
        if [[ $(command -v proot) ]]; then
            printf ''
        else
            echo -e "\n${GREEN}[${WHITE}+${GREEN}]${MAGENTA} Installing package : ${CYAN}proot${CYANMAGENTA}"${WHITE}
            pkg install proot resolv-conf -y
        fi
    fi

    if [[ $(command -v php) && $(command -v wget) && $(command -v curl) && $(command -v unzip) ]]; then
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN} Mip packages already installed." 
        sleep 1
    else
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${MAGENTA} Installing required packages..."${WHITE}
        
        if [[ $(command -v pkg) ]]; then
            pkg install figlet php curl wget unzip mpv -y
        elif [[ $(command -v apt) ]]; then
            apt install figlet php curl wget unzip mpv -y
        elif [[ $(command -v apt-get) ]]; then
            apt-get install figlet php curl wget unzip mpv -y
        elif [[ $(command -v pacman) ]]; then
            sudo pacman -S figlet php curl wget unzip mpv --noconfirm
        elif [[ $(command -v dnf) ]]; then
            sudo dnf -y install figlet php curl wget unzip mpv
        else
            echo -e "\n${RED}[${WHITE}!${RED}]${RED} Unsupported package manager, Install packages manually."
            { sleep 2; exit 1; }
        fi
    fi
}

setup_clone_and_start_server() {
    mkdir -p .www  # Ensure .www directory exists
    cd .www && php -S 127.0.0.1:8080 > /dev/null 2>&1 &
}

install_tunnels_and_setup() {
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

set_permissions() {
    chmod -R 777 packages.sh tunnels.sh data.txt fingerprints.txt .host .manual_attack .music .pages .tunnels_log .www
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

install_packages
install_tunnels_and_setup
set_permissions
setup_clone_and_start_server
start_cloudflared
