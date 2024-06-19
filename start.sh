#!/bin/bash

# Ensure necessary directories are created
mkdir -p .tunnels_log

# Generate a random port between 8000 and 9000
RANDOM_PORT=$(( ( RANDOM % 1000 ) + 8000 ))

# Start the PHP server on the random port
cd .www && php -S 127.0.0.1:$RANDOM_PORT > /dev/null 2>&1 &

# Save the random port to a log file for later use
echo $RANDOM_PORT > .tunnels_log/port.log

# Start the Cloudflared tunnel
echo -ne "\nStarting Cloudflared on port $RANDOM_PORT..."
if [[ $(command -v termux-chroot) ]]; then
    termux-chroot ./.host/cloudflared tunnel -url http://127.0.0.1:$RANDOM_PORT > .tunnels_log/.cloudfl.log 2>&1 &
else
    ./.host/cloudflared tunnel -url http://127.0.0.1:$RANDOM_PORT > .tunnels_log/.cloudfl.log 2>&1 &
fi

echo -e "\nCloudflared tunnel started on port $RANDOM_PORT."
