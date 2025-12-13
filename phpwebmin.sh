#!/bin/sh

# Variables
version="1.1"
date="13/12/2025"
github_link="https://github.com/rafa3d/PHPWebMin"
WEB_DIR="/var/www/phpwebmin"

# --- Helpers ---
is_root() { [ "$(id -u)" -eq 0 ]; }

run() {
  if is_root; then
    sh -c "$*"
  else
    if command -v sudo >/dev/null 2>&1; then
      sudo sh -c "$*"
    else
      echo "ERROR: necesito permisos root (o sudo)."
      exit 1
    fi
  fi
}

detect_os() {
  if [ -f /etc/alpine-release ]; then
    echo "alpine"
    return
  fi
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      alpine) echo "alpine" ;;
      debian|ubuntu|linuxmint|pop) echo "debian" ;;
      *) echo "unknown" ;;
    esac
  else
    echo "unknown"
  fi
}

php_has_curl() {
  command -v php >/dev/null 2>&1 || return 1
  php -m 2>/dev/null | grep -qi '^curl$'
}

install_php_curl_debian() {
  if php_has_curl; then
    echo "PHP curl module already enabled."
    return 0
  fi
  echo "Installing php-curl (apt)..."
  run "apt install -y php-curl >/dev/null 2>&1 || true"
}

install_php_curl_alpine() {
  if php_has_curl; then
    echo "PHP curl module already enabled."
    return 0
  fi
  echo "Installing php-curl (apk)..."
  # Alpine 3.22 normalmente: php83-curl
  run "apk add --no-cache php83-curl >/dev/null 2>&1 || apk add --no-cache php-curl >/dev/null 2>&1 || true"
}

# Header
echo "
 ___ _  _ _____      __   _    __  __ _
| _ \ || | _ \ \    / /__| |__|  \/  (_)_ _
|  _/ __ |  _/\ \/\/ / -_) '_ \ |\/| | | ' \\
|_| |_||_|_|   \_/\_/\___|_.__/_|  |_|_|_||_|
Minimal WebServer script $version $date
"

# Ask for the port number (POSIX)
while :; do
  printf "Enter the port number [default: 80]: "
  read -r PORT
  [ -z "$PORT" ] && PORT="80"

  case "$PORT" in
    *[!0-9]*|"") echo "Invalid port. Please enter a number between 1 and 65535." ;;
    *)
      if [ "$PORT" -ge 1 ] 2>/dev/null && [ "$PORT" -le 65535 ] 2>/dev/null; then
        break
      else
        echo "Invalid port. Please enter a number between 1 and 65535."
      fi
    ;;
  esac
done

echo "Using port $PORT..."

OS="$(detect_os)"
echo "Detected OS: $OS"

# --- Package management + cleanup of other web servers ---
if [ "$OS" = "debian" ]; then
  echo "Updating package lists (apt)..."
  run "apt update -qq >/dev/null"

  echo "Removing unnecessary web services (apt)..."
  run "apt remove -y nginx apache2 lighttpd httpd >/dev/null 2>&1 || true"

  echo "Installing PHP CLI and Nano (apt)..."
  command -v php >/dev/null 2>&1 || run "apt install -y php-cli >/dev/null 2>&1"
  command -v nano >/dev/null 2>&1 || run "apt install -y nano >/dev/null 2>&1"

  # NEW: php-curl
  install_php_curl_debian

elif [ "$OS" = "alpine" ]; then
  echo "Updating package lists (apk)..."
  run "apk update >/dev/null"

  echo "Removing unnecessary web services (apk)..."
  run "apk del --quiet nginx apache2 lighttpd httpd 2>/dev/null || true"

  echo "Installing PHP CLI and Nano (apk)..."
  if ! command -v php >/dev/null 2>&1; then
    run "apk add --no-cache php83 php83-cli >/dev/null 2>&1 || apk add --no-cache php php-cli >/dev/null 2>&1"
  fi
  command -v nano >/dev/null 2>&1 || run "apk add --no-cache nano >/dev/null 2>&1"

  # OpenRC (si no existe, lo instalamos)
  command -v rc-service >/dev/null 2>&1 || run "apk add --no-cache openrc >/dev/null 2>&1"

  # NEW: php-curl
  install_php_curl_alpine

else
  echo "ERROR: no reconozco el sistema. (Necesito Debian/Ubuntu o Alpine)"
  exit 1
fi

# --- Timezone Europe/Madrid ---
if [ "$OS" = "debian" ] && command -v timedatectl >/dev/null 2>&1; then
  CURRENT_TZ="$(timedatectl show --value -p Timezone 2>/dev/null || true)"
  if [ "$CURRENT_TZ" != "Europe/Madrid" ]; then
    echo "Setting timezone to Europe/Madrid..."
    run "timedatectl set-timezone Europe/Madrid >/dev/null 2>&1 || true"
  else
    echo "Timezone is already set to Europe/Madrid."
  fi
elif [ "$OS" = "alpine" ]; then
  echo "Setting timezone to Europe/Madrid (Alpine)..."
  run "apk add --no-cache tzdata >/dev/null 2>&1 || true"
  if [ -f /usr/share/zoneinfo/Europe/Madrid ]; then
    run "cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime"
    run "echo 'Europe/Madrid' > /etc/timezone"
  fi
fi

# --- Web dir + index.php ---
echo "Ensuring the web directory exists at $WEB_DIR"
run "mkdir -p '$WEB_DIR'"

run "cat > '$WEB_DIR/index.php' <<'PHP'
<?php
\$version = \"$version\";
\$date = \"$date\";
\$github_link = \"$github_link\";
echo 'Hello World from PHPWebMin ' . \$version . '!';
echo '<br>Date: ' . \$date;
echo '<br>GitHub: <a href=\"' . \$github_link . '\" target=\"_blank\">' . \$github_link . '</a>';

echo '<br><br>curl_init exists? ';
echo function_exists('curl_init') ? 'YES' : 'NO';
PHP
"

# --- Service setup ---
if [ "$OS" = "debian" ] && command -v systemctl >/dev/null 2>&1; then
  SERVICE_FILE="/etc/systemd/system/phpwebmin.service"
  echo "Configuring systemd service..."
  run "cat > '$SERVICE_FILE' <<EOF
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
"
  echo "Reloading and starting the PHPWebMin service..."
  run "systemctl daemon-reload >/dev/null 2>&1"
  run "systemctl enable phpwebmin >/dev/null 2>&1"
  run "systemctl restart phpwebmin >/dev/null 2>&1"

elif [ "$OS" = "alpine" ] && command -v rc-service >/dev/null 2>&1; then
  INIT_FILE="/etc/init.d/phpwebmin"
  echo "Configuring OpenRC service..."
  run "cat > '$INIT_FILE' <<EOF
#!/sbin/openrc-run
name=\"phpwebmin\"
description=\"PHPWebMin Web Server $version\"

command=\"/usr/bin/php\"
command_args=\"-S 0.0.0.0:$PORT -t $WEB_DIR\"
command_background=\"yes\"
pidfile=\"/run/\${name}.pid\"
output_log=\"/var/log/\${name}.log\"
error_log=\"/var/log/\${name}.err\"

depend() {
  need net
}
EOF
"
  run "chmod +x '$INIT_FILE'"

  run "rc-update add phpwebmin default >/dev/null 2>&1 || true"
  run "rc-service phpwebmin restart >/dev/null 2>&1 || rc-service phpwebmin start >/dev/null 2>&1 || true"
else
  echo "No systemd/OpenRC detectado. Arranco en foreground para que lo gestiones tú:"
  echo "  /usr/bin/php -S 0.0.0.0:$PORT -t $WEB_DIR"
fi

# --- Clean up ---
if [ "$OS" = "debian" ]; then
  echo "Cleaning up unused packages..."
  run "apt autoremove -y >/dev/null 2>&1"
  run "apt clean >/dev/null 2>&1"
elif [ "$OS" = "alpine" ]; then
  run "rm -rf /var/cache/apk/* >/dev/null 2>&1 || true"
fi

# --- Show URL ---
PUBLIC_IP="$( (command -v curl >/dev/null 2>&1 && curl -4 -s ifconfig.me) || echo "YOUR_SERVER_IP" )"
echo "PHPWebMin $version setup completed!"
echo "Your web server is running at: http://$PUBLIC_IP:$PORT"
