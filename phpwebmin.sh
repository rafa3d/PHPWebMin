#!/bin/bash

# PHPWebMin 1.0 ASCII Art Header
echo "
#################################################
#                                               #
#      ____  _  _   __        __  _  _          #
#     |  _ \| || |  \ \      / / | || |         #
#     | |_) | || |_  \ \ /\ / /__| || |_        #
#     |  __/|__   _|  \ V  V / _ \__   _|       #
#     |_|      |_|     \_/\_/\___/  |_|         #
#                                               #
#       Minimal WebServer Setup Script          #
#                                               #
#################################################
"

# Step 1: Prompt for the port number
read -p "Enter the port number to use for the web server [default: 80]: " PORT
PORT=${PORT:-80}  # Use 80 if no input is given

# Step 2: Update system and remove unnecessary services
echo "Updating system and removing unnecessary web services..."
sudo apt update
sudo apt remove -y nginx apache2 lighttpd httpd

# Step 3: Install PHP CLI and Nano
echo "Installing PHP CLI and Nano text editor..."
sudo apt install -y php-cli nano

# Step 4: Set timezone to Europe/Madrid
echo "Setting timezone to Europe/Madrid..."
sudo timedatectl set-timezone Europe/Madrid

# Step 5: Create the web directory
WEB_DIR="/var/www/phpwebmin"
echo "Creating the web directory at $WEB_DIR..."
sudo mkdir -p $WEB_DIR
echo "<?php echo 'Hello World from PHPWebMin 1.0';" | sudo tee $WEB_DIR/index.php

# Step 6: Configure systemd service for PHP built-in web server
SERVICE_FILE="/etc/systemd/system/phpwebmin.service"
echo "Configuring the PHP built-in web server to start on boot..."
sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=PHPWebMin Web Server
After=network.target

[Service]
ExecStart=/usr/bin/php -S 0.0.0.0:$PORT -t $WEB_DIR
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF"

# Step 7: Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable phpwebmin
sudo systemctl start phpwebmin

# Step 8: Clean up unnecessary packages
echo "Cleaning up unnecessary packages..."
sudo apt autoremove -y
sudo apt clean

# Step 9: Fetch and display the public IP address
PUBLIC_IP=$(curl -s ifconfig.me)
echo "PHPWebMin 1.0 setup completed successfully!"
echo "Your web server is running at http://$PUBLIC_IP:$PORT"
echo "Click the link above to access your web server."
