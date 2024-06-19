#!/bin/bash

# Stop the Cloudflared tunnel
echo -ne "\nStopping Cloudflared..."
pkill -f cloudflared

# Stop the PHP server
echo -ne "\nStopping PHP server..."
pkill -f php

echo -e "\nCloudflared tunnel and PHP server stopped."
