#!/bin/bash

set -euo pipefail

echo "--------------------------------------"
echo "🚀 Starting Frontend Deployment"
echo "--------------------------------------"

# -----------------------------
# Variables
# -----------------------------
APP_DIR="${WORKSPACE}/app/frontend/simple-index-html"
DEST_DIR="/var/www/html"
SERVICE="nginx"
BACKUP_DIR="/var/www/html_backup_$(date +%F-%T)"

# -----------------------------
# Install Nginx (if not installed)
# -----------------------------
if ! command -v nginx &> /dev/null
then
    echo "📦 Installing Nginx..."
    sudo apt update -y
    sudo apt install -y nginx
fi

# -----------------------------
# Backup existing deployment
# -----------------------------
if [ -d "$DEST_DIR" ] && [ "$(ls -A $DEST_DIR)" ]; then
    echo "📁 Taking backup of existing files..."
    sudo cp -r $DEST_DIR $BACKUP_DIR
fi

# -----------------------------
# Deploy new files
# -----------------------------
echo "📁 Deploying new frontend..."

sudo rm -rf ${DEST_DIR:?}/*
sudo cp -r $APP_DIR/* $DEST_DIR/

# -----------------------------
# Set permissions
# -----------------------------
sudo chown -R www-data:www-data $DEST_DIR

# -----------------------------
# Restart Nginx
# -----------------------------
echo "🔄 Restarting Nginx..."
sudo systemctl restart $SERVICE

# -----------------------------
# Health Check
# -----------------------------
echo "🌐 Checking service..."
sudo systemctl status $SERVICE --no-pager

echo "--------------------------------------"
echo "✅ Deployment Successful"
echo "--------------------------------------"
