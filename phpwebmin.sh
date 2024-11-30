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
sudo apt update -qq >/dev/null
sudo apt remove -y nginx apache2 lighttpd httpd >/dev/null 2>&1

# Step 3: Install PHP CLI and Nano
echo "Installing PHP CLI and Nano text editor..."
sudo apt install -y php-cli nano >/dev/null 2>&1

# Step 4: Set timezone to Europe/Madrid
echo "Setting timezone to Europe/Madrid..."
sudo timedatectl set-timezone Europe/Madrid >/dev/null 2>&1

# Step 5: Create the web directory
WEB_DIR="/var/www/phpwebmin"
echo "Creating the web directory at $WEB_DIR..."
sudo mkdir -p $WEB_DIR
echo "<?php echo 'Hello World from PHPWebMin 1.0';" | sudo tee $WEB_DIR/index.php >/dev/null

# Step 6: Configure systemd service for PHP built-in web server
SERVICE_FILE="/etc/systemd/system/phpwebmin.service"
echo "Configuring the PHP built-in web server to start on boot..."
sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=PHPWebMin Web Server
After=network.target

[Service]
ExecStart=/usr/bin/php -
