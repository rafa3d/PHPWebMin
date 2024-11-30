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

# Step 2: Update the system (silent if already updated)
echo "Updating package lists..."
sudo apt update -qq >/dev/null

# Step 3: Remove unnecessary services (if installed)
echo "Removing unnecessary web services (if present)..."
sudo apt remove -y nginx apache2 lighttpd httpd >/dev/null 2>&1 || true

# Step 4: Install PHP CLI and Nano if not already installed
echo "Installing PHP CLI and Nano (if not already installed)..."
if ! command -v php > /dev/null; then
    sudo apt install -y php-cli >/dev/null 2>&1
else
    echo "PHP CLI is already installed."
fi

if ! command -v nano > /dev/null; then
    sudo apt install -y nano >/dev/null 2>&1
else
    echo "Nano is already installed."
fi

# Step 5: Set timezone to Europe/Madrid if not already set
CURRENT_TZ=$(timedatectl show --value -p Timezone)
if [ "$CURRENT_TZ" != "Europe/Madrid" ]; then
    echo "Setting timezone to Europe/Madrid..."
    sudo timedatectl set-timezone Europe/Madrid >/dev/null 2>&1
else
    echo "Timezone is already set to Europe/Madrid."
fi

# Step 6: Create or update the web directory
WEB_DIR="/var/www/phpwebmin"
echo "Ensuring the web directory exists at $WEB_DIR..."
sudo mkdir -p $WEB_DIR

# Ensure the "Hello World" index.php exists
echo "Setting up index.php..."
echo "<?php echo 'Hello World from PHPWebMin 1.0';" | sudo tee $WEB_DIR/index.php >/dev/null

# Step 7: Configure systemd service for PHP built-in web server
SERVICE_FILE="/etc/systemd/system/phpwebmin.service"
echo "Configuring PHPWebMin service..."
sudo tee $SERVICE_FILE >/dev/null <<EOF
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
EOF

# Reload systemd and ensure the service is enabled and running
echo "Reloading systemd and ensuring the service is enabled..."
sudo systemctl daemon-reload >/dev/null 2>&1
sudo systemctl enable phpwebmin >/dev/null 2>&1
sudo systemctl restart phpwebmin >/dev/null 2>&1

# Step 8: Clean up unnecessary packages
echo "Cleaning up unnecessary packages..."
sudo apt autoremove -y >/dev/null 2>&1
sudo apt clean >/dev/null 2>&1

# Step 9: Fetch and display the public IP address
PUBLIC_IP=$(curl -s ifconfig.me)
echo "PHPWebMin 1.0 setup completed successfully!"
echo "Your web server is running at http://$PUBLIC_IP:$PORT"
echo "Click the link above to access your web server."
