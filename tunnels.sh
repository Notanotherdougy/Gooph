#!/bin/bash



# Terminal Colors

RED="$(printf '\033[31m')"  
GREEN="$(printf '\033[32m')"  
ORANGE="$(printf '\033[33m')"  
BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  
CYAN="$(printf '\033[36m')"  
WHITE="$(printf '\033[37m')" 
BLACK="$(printf '\033[30m')"


echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing required tunnels."


# Cloudflared Download
get_cloudflared() {
	
	url="$1"
	file=`basename $url`
	if [[ -e "$file" ]]; then
	
		rm -rf "$file"
	fi
	
	wget --no-check-certificate "$url" > /dev/null 2>&1
	
	if [[ -e "$file" ]]; then
		mv -f "$file" .host/cloudflared > /dev/null 2>&1
		chmod +x .host/cloudflared > /dev/null 2>&1
		
	else
		echo -e "\n${RED}[${WHITE}!${RED}]${RED} Error, Install Cloudflared manually."
		{ clear; exit 1; }
	fi
}




# Download and install Cloudflared 

cloudflared_download_and_install() {
	
	if [[ -e ".host/cloudflared" ]]; then
		echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN} Cloudflared already installed."
		sleep 1
	
	else
	
		echo -e "\n${GREEN}[${WHITE}+${GREEN}]${MAGENTA} Downloading and Installing Cloudflared..."${WHITE}
		
		architecture=$(uname -m)
		
		if [[ ("$architecture" == *'arm'*) || ("$architecture" == *'Android'*) ]]; then
			get_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm'
		
		elif [[ "$architecture" == *'aarch64'* ]]; then
			get_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64'
		
		elif [[ "$architecture" == *'x86_64'* ]]; then
			get_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64'
		
		else
			get_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386'
		fi
	fi

}
cloudflared_download_and_install
