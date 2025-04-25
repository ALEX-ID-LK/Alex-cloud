#!/bin/bash

# WhatsApp Bot Hosting Setup Script for Pterodactyl
# VPS IP: 146.190.95.209 | Ubuntu 22.04

set -e

MYSQL_ROOT_PASS="Alexpair#727"
PANEL_DB_PASS="Alexpair#727"
PANEL_EMAIL="alexidprogrammerofficial@gmail.com"
PANEL_URL="http://146.190.95.209"
TIMEZONE="Asia/Colombo"

echo "[1/10] Updating..."
apt update -y && apt upgrade -y

echo "[2/10] Installing packages..."
apt install -y nginx mysql-server php php-cli php-mbstring php-zip php-bcmath php-gd php-curl php-mysql php-xml php-fpm unzip curl git redis-server composer ufw docker.io docker-compose

echo "[3/10] Enabling services..."
systemctl enable --now redis-server mysql docker

echo "[4/10] Configuring MySQL..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASS'; FLUSH PRIVILEGES;"
mysql -uroot -p$MYSQL_ROOT_PASS -e "CREATE DATABASE panel;"
mysql -uroot -p$MYSQL_ROOT_PASS -e "CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY '$PANEL_DB_PASS';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL ON panel.* TO 'ptero'@'127.0.0.1'; FLUSH PRIVILEGES;"

echo "[5/10] Installing Pterodactyl Panel..."
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz && rm panel.tar.gz
cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate --force

php artisan p:environment:setup --author="ALEX" --email="$PANEL_EMAIL" --url="$PANEL_URL" --timezone="$TIMEZONE" --cache="redis" --session="redis" --queue="redis"

php artisan p:environment:database --host=127.0.0.1 --port=3306 --database=panel --username=ptero --password="$PANEL_DB_PASS"

php artisan migrate --seed --force
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 storage/* bootstrap/cache/

echo "[6/10] Configuring NGINX..."
cat > /etc/nginx/sites-available/pterodactyl <<EOF
server {
    listen 80;
    server_name 146.190.95.209;

    root /var/www/pterodactyl/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

echo "[7/10] Installing Wings..."
curl -L https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64 -o /usr/local/bin/wings
chmod +x /usr/local/bin/wings
mkdir -p /etc/pterodactyl

echo "[8/10] Done!"
echo "Visit: http://146.190.95.209 and finish setup (create admin)."
