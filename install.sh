#!/bin/bash

# Update the system
echo "Updating the system..."
sudo apt update && sudo apt upgrade -y

# Install required dependencies
echo "Installing dependencies..."
sudo apt install -y git curl unzip wget sudo lsb-release software-properties-common

# Install PHP 8.2
echo "Installing PHP 8.2..."
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install -y php8.2 php8.2-cli php8.2-fpm php8.2-curl php8.2-mysql php8.2-gd php8.2-xml php8.2-mbstring php8.2-bcmath php8.2-zip

# Set PHP 8.2 as default
echo "Setting PHP 8.2 as the default version..."
sudo update-alternatives --set php /usr/bin/php8.2
sudo update-alternatives --set phpize /usr/bin/phpize8.2
sudo update-alternatives --set php-config /usr/bin/php-config8.2

# Install MySQL
echo "Installing MySQL..."
sudo apt install -y mysql-server

# Configure MySQL root password
echo "Configuring MySQL root password..."
sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'newpassword'; FLUSH PRIVILEGES;"

# Install Nginx
echo "Installing Nginx..."
sudo apt install -y nginx

# Install Certbot for SSL
echo "Installing Certbot for SSL..."
sudo apt install -y certbot python3-certbot-nginx

# Install Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Clone the repository
echo "Cloning the Pterodactyl panel repository..."
git clone https://github.com/ALEX-ID-LK/Alex-cloud.git
cd Alex-cloud

# Run the install script
echo "Running the installation script..."
sudo bash install.sh

# Create the Nginx config file for Pterodactyl
echo "Setting up Nginx configuration for Pterodactyl..."
sudo bash -c 'cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
server {
    listen 80;
    server_name example.com;  # Change this to your domain name

    root /var/www/pterodactyl/public;

    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    error_log /var/log/nginx/pterodactyl_error.log;
    access_log /var/log/nginx/pterodactyl_access.log;
}
EOF'

# Create symbolic link for Nginx
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

# Restart Nginx if config test passed
echo "Restarting Nginx..."
sudo systemctl restart nginx

# Install Wings Daemon
echo "Installing Wings Daemon..."
cd /var/www/pterodactyl
git clone https://github.com/pterodactyl/wings.git
cd wings
./scripts/install.sh

# Enable and start Wings service
echo "Enabling and starting Wings service..."
sudo systemctl enable wings
sudo systemctl start wings

# Set up SSL using Certbot
echo "Setting up SSL for Nginx..."
sudo certbot --nginx -d your-domain.com  # Replace with your domain

# Final steps
echo "Installation complete. Please access your Pterodactyl Panel in your browser."
