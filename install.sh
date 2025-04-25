#!/bin/bash

# [1/10] Updating system...
echo "[1/10] Updating system..."
apt update -y && apt upgrade -y

# [2/10] Installing required packages...
echo "[2/10] Installing packages..."
apt install -y git curl wget unzip sudo lsb-release software-properties-common

# [3/10] Installing dependencies...
echo "[3/10] Installing dependencies..."
apt install -y php-cli php-curl php-fpm php-mbstring php-xml php-mysql php-zip php-bcmath php-gd php-mysql php-mbstring composer docker.io docker-compose redis-server nginx ufw

# [4/10] Configuring MySQL...
echo "[4/10] Configuring MySQL..."

# Set MySQL root password (replace YOUR_PASSWORD_HERE with strong password)
MYSQL_ROOT_PASSWORD="AlexStrong@123"

# Set root password
echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;" | sudo mysql

# Create database and user for Pterodactyl
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE panel;"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY 'StrongPanelPass123!';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

# [5/10] Installing Pterodactyl Panel...
echo "[5/10] Installing Pterodactyl Panel..."
cd /var/www
git clone https://github.com/pterodactyl/panel.git pterodactyl
cd pterodactyl
composer install --no-dev --optimize-autoloader

# [6/10] Setting up environment...
echo "[6/10] Setting up environment..."
cp .env.example .env
php artisan key:generate --force

# [7/10] Configuring NGINX...
echo "[7/10] Configuring NGINX..."
cp /var/www/pterodactyl/nginx/pterodactyl.conf /etc/nginx/sites-available/pterodactyl
ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/

# [8/10] Setting up SSL for NGINX...
echo "[8/10] Setting up SSL for NGINX..."
apt install -y certbot python3-certbot-nginx
certbot --nginx -d YOURDOMAIN.com

# [9/10] Installing Wings...
echo "[9/10] Installing Wings..."
cd /home
git clone https://github.com/pterodactyl/wings.git
cd wings
./scripts/install.sh

# [10/10] Enabling services and starting...
echo "[10/10] Enabling services and starting..."
systemctl enable redis-server
systemctl enable mysql
systemctl enable nginx
systemctl enable wings
systemctl start redis-server
systemctl start mysql
systemctl start nginx
systemctl start wings

echo "Installation complete! Please configure Pterodactyl Panel in your browser."
