#!/bin/bash

# Variables
version="1.0"
date="30/11/2024"

# Header
echo "
  ___ _  _ _____      __   _    __  __ _      
 | _ \ || | _ \ \    / /__| |__|  \/  (_)_ _  
 |  _/ __ |  _/\ \/\/ / -_) '_ \ |\/| | | ' \ 
 |_| |_||_|_|   \_/\_/\___|_.__/_|  |_|_|_||_|
                                              
Minimal WebServer script $version $date
"

read -p "Enter the port number [default: 80]: " PORT
PORT=${PORT:-80}

echo "Updating package lists..."
sudo apt update -qq >/dev/null

echo "Removing unnecessary web services..."
sudo apt remove -y nginx apache2 lighttpd httpd >/dev/null 2>&1 || true

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

CURRENT_TZ=$(timedatectl show --value -p Timezone)
if [ "$CURRENT_TZ" != "Europe/Madrid" ]; then
    echo "Setting timezone to Europe/Madrid..."
    sudo timedatectl set-timezone Europe/Madrid >/dev/null 2>&1
else
    echo "Timezone is already set to Europe/Madrid."
fi

WEB_DIR="/var/www/phpwebmin"
echo "Ensuring the web directory exists at $WEB_DIR..."
sudo mkdir -p $WEB_DIR
echo "<?php echo 'Hello World from PHPWebMin $version';" | sudo tee $WEB_DIR/index.php >/dev/null

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

echo "Reloading and starting the PHPWebMin service..."
sudo systemctl daemon-reload >/dev/null 2>&1
sudo systemctl enable phpwebmin >/dev/null 2>&1
sudo systemctl restart phpwebmin >/dev/null 2>&1

echo "Cleaning up unused packages..."
sudo apt autoremove -y >/dev/null 2>&1
sudo apt clean >/dev/null 2>&1

PUBLIC_IP=$(curl -s ifconfig.me)
echo "PHPWebMin $version setup completed!"
echo "Your web server is running at http://$PUBLIC_IP:$PORT"
