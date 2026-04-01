#!/bin/bash

set -euo pipefail

echo "🚀 Starting WordPress Deployment (Apache)"

WEB_ROOT="/var/www/html"

# Install packages
sudo apt update
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql unzip curl

# Start services
sudo systemctl enable apache2
sudo systemctl enable mysql

sudo systemctl start apache2
sudo systemctl start mysql

# Download WordPress
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

# Deploy
sudo rm -rf $WEB_ROOT/*
sudo cp -r wordpress/* $WEB_ROOT/

# Set permissions
sudo chown -R www-data:www-data $WEB_ROOT

# Restart Apache
sudo systemctl restart apache2

echo "✅ WordPress deployed using Apache"
