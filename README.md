# **PHPWebMin 1.0**

**PHPWebMin** is a lightweight script designed to set up a minimal web server environment by removing unnecessary services, installing essential tools, and configuring a basic PHP-capable web directory. Perfect for developers who need a clean and efficient setup.

---

## **Features**

- Automatically removes unnecessary web services like **Nginx**, **Apache**, and **Lighttpd**.
- Installs **PHP CLI** (version 5.4 or later) for command-line PHP scripting.
- Installs the lightweight **Nano** text editor for quick editing.
- Configures a universal web directory at `/var/www/phpwebmin` to handle PHP requests.
- Ensures the web server starts on boot and remains active.
- Displays "Hello World from PHPWebMin 1.0" when accessed from a browser.
- Sets the server timezone to **Europe/Madrid**.
- Cleans up unused packages to optimize the system.

---

## **Quick Start**

Run the following command to execute the script directly from GitHub:

```bash
curl -sSL https://raw.githubusercontent.com/rafa3d/PHPWebMin/main/phpwebmin.sh | sudo bash
