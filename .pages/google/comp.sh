#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install necessary dependencies
install_dependencies() {
    echo "Installing necessary dependencies..."
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y php-cli php-zip unzip wget
    elif command_exists yum; then
        sudo yum install -y php-cli php-zip unzip wget
    else
        echo "Package manager not supported. Please install PHP and required extensions manually."
        exit 1
    fi
}

# Install Composer
install_composer() {
    echo "Downloading Composer installer..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

    echo "Verifying installer..."
    EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
    ACTUAL_SIGNATURE=$(php -r "echo hash_file('sha384', 'composer-setup.php');")

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
        echo 'ERROR: Invalid installer signature'
        rm composer-setup.php
        exit 1
    fi

    echo "Installing Composer..."
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    RESULT=$?
    rm composer-setup.php

    if [ $RESULT -ne 0 ]; then
        echo 'ERROR: Composer installation failed'
        exit 1
    fi

    echo 'Composer successfully installed'
}

# Install Composer dependencies
install_composer_dependencies() {
    echo "Running composer install..."
    composer install

    if [ $? -ne 0 ]; then
        echo 'ERROR: Composer install failed'
        exit 1
    fi

    echo 'Composer dependencies installed successfully'
}

# Check and install dependencies
if ! command_exists php; then
    echo "PHP is not installed. Installing PHP and necessary extensions..."
    install_dependencies
fi

if ! command_exists composer; then
    echo "Composer is not installed. Installing Composer..."
    install_composer
fi

# Install project dependencies using Composer
install_composer_dependencies
