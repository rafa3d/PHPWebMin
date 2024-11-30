#!/bin/bash

# Variables
version="1.0"
date="30/11/2024"
github_link="https://github.com/rafa3d/PHPWebMin"

# Header
echo "
 ___ _  _ _____      __   _    __  __ _      
| _ \ || | _ \ \    / /__| |__|  \/  (_)_ _  
|  _/ __ |  _/\ \/\/ / -_) '_ \ |\/| | | ' \ 
|_| |_||_|_|   \_/\_/\___|_.__/_|  |_|_|_||_|
Minimal WebServer script $version $date
"

# Ask for the port number
while true; do
    read -p "Enter the port number [default: 80]: " PORT
    PORT=${PORT:-80}
    if [[ $PORT =~ ^[0-9]+$ ]] && ((PORT > 0 && PORT <= 65535)); then
        break
    else
        echo "Invalid port. Please enter a number between 1 and 65535."
    fi
done

echo "Using port $PORT..."

# Update package lists
echo "Updating package lists..."
sudo apt update -qq >/dev/null

# Remove unnecessary web services
echo "Removing unnecessary web services..."
sudo apt remove -y nginx apache2 lighttpd httpd >/dev/null 2>&1 || true

# Install PHP CLI and Nano
echo "Installing PHP CLI and Nano..."
if ! command -v php >/dev/null; then
    sudo apt install -y php-cli >/dev/null 2>&1
else
    echo "PHP CLI is already installed."
fi

if ! command -v nano >/dev/null; then
    sudo apt install -y nano >/dev/null 2>&1
else
    echo "Nano is already installed."
fi

# Set timezone to Europe/Madrid
CURRENT_TZ=$(timedatectl show --value -p Timezone)
if [ "$CURRENT_TZ" != "Europe/Madrid" ]; then
    echo "Setting timezone to Europe/Madrid..."
    sudo timedatectl set-timezone Europe/Madrid >/dev/null 2>&1
else
    echo "Timezone is already set to Europe/Madrid."
fi

# Create or update the web directory
WEB_DIR="/var/www/phpwebmin"
echo "Ensuring the web directory exists at $WEB_DIR..."
sudo mkdir -p $WEB_DIR
echo "<?php 
echo 'Hello World from PHPWebMin $version!'; 
echo '<br>Date: $date'; 
echo '<br>GitHub: <a href=\"$github_link\" target=\"_blank\">$github_link</a>';
?>" | sudo tee $WEB_DIR/index.php >/dev/null

# Configure systemd service for PHP built-in web server
SERVICE_FILE="/etc/systemd/system/phpwebmin.service"
echo "Configuring PHPWebMin service..."
sudo tee $SERVICE_FILE >/dev/null <<EOF
[Unit]
Description=PHPWebMin Web Server $version
After=network.target

[Service]
ExecStart=/usr/bin/php -S 0.0.0.0:$PORT -t $WEB_DIR
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
echo "Reloading and starting the PHPWebMin service..."
sudo systemctl daemon-reload >/dev/null 2>&1
sudo systemctl enable phpwebmin >/dev/null 2>&1
sudo systemctl restart phpwebmin >/dev/null 2>&1

# Clean up unused packages
echo "Cleaning up unused packages..."
sudo apt autoremove -y >/dev/null 2>&1
sudo apt clean >/dev/null 2>&1

# Show the server URL
PUBLIC_IP=$(curl -s ifconfig.me)
echo "PHPWebMin $version setup completed!"
echo "Your web server is running at http://$PUBLIC_IP:$PORT"
