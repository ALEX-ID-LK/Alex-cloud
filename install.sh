#!/bin/bash

# Exit on any failure
set -e

echo "System updating..."
apt update -y && apt upgrade -y

echo "Installing required packages..."
apt install -y curl wget zip unzip tar nginx mariadb-server php php-cli php-mysql php-gd php-mbstring php-xml php-curl php-zip php-bcmath php-tokenizer php-common php-fpm php-mysqlnd php-memcached php-redis redis git composer

echo "Starting MariaDB..."
systemctl enable mariadb
systemctl start mariadb

echo "Creating database and user..."
mysql -e "CREATE DATABASE panel;"
mysql -e "CREATE USER 'paneluser'@'localhost' IDENTIFIED BY 'strongpassword';"
mysql -e "GRANT ALL PRIVILEGES ON panel.* TO 'paneluser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "Downloading Pterodactyl panel..."
cd /var/www
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
mkdir -p /var/www/pterodactyl
tar -xzvf panel.tar.gz -C /var/www/pterodactyl
cd /var/www/pterodactyl

cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate --force

echo "Configuring environment..."
php artisan p:environment:setup --author="alexidprogrammerofficial@gmail.com" --url="http://46.137.203.164" --timezone="Asia/Colombo" --cache="redis" --session="redis" --queue="redis" --no-interaction
php artisan p:environment:database --host=127.0.0.1 --port=3306 --database=panel --username=paneluser --password=strongpassword --no-interaction
php artisan p:environment:mail --driver=log --no-interaction

php artisan migrate --seed --force
php artisan p:user:make --email=alexidprogrammerofficial@gmail.com --username=admin --name=Alex --password=Alexpair#727 --admin=1

chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 storage/* bootstrap/cache/

echo "Configuring NGINX..."
cat > /etc/nginx/sites-available/pterodactyl <<EOF
server {
    listen 80;
    server_name 46
