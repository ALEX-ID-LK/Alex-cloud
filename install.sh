#!/bin/bash

# Exit if error
set -e

echo "System updating..."
sudo apt update -y && sudo apt upgrade -y

echo "Installing required packages..."
sudo apt install -y curl wget zip unzip tar nginx mariadb-server php php-cli php-mysql php-gd php-mbstring php-xml php-curl php-zip php-bcmath php-tokenizer php-common php-fpm php-mysqlnd php-memcached php-redis redis git composer

echo "Starting MariaDB..."
sudo systemctl enable mariadb
sudo systemctl start mariadb

echo "Dropping old DB if exists..."
sudo mysql -e "DROP DATABASE IF EXISTS panel;"
sudo mysql -e "CREATE DATABASE panel;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'paneluser'@'localhost' IDENTIFIED BY 'strongpassword';"
sudo mysql -e "GRANT ALL PRIVILEGES ON panel.* TO 'paneluser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "Downloading Pterodactyl panel..."
cd /var/www
sudo curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
sudo mkdir -p /var/www/pterodactyl
sudo tar -xzvf panel.tar.gz -C /var/www/pterodactyl
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
sudo bash -c 'cat > /etc/nginx/sites-available/pterodactyl <<EOF
server {
    listen 80;
    server_name 46.137.203.164;

    root /var/www/pterodactyl/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF'

sudo ln -sf /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

echo "Pterodactyl panel installed successfully!"
