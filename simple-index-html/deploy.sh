#!/bin/bash

set -euo pipefail

echo "--------------------------------------"
echo "🚀 Starting Full Stack Deployment"
echo "--------------------------------------"

# -----------------------------
# Variables
# -----------------------------
WORKSPACE_DIR="${WORKSPACE}"
FRONTEND_DIR="$WORKSPACE_DIR/app/frontend/simple-index-html"
BACKEND_DIR="$WORKSPACE_DIR/app/backend"

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
# Install Node + PM2 (if not installed)
# -----------------------------
if ! command -v node &> /dev/null
then
    echo "📦 Installing Node.js..."
    sudo apt install -y nodejs npm
fi

if ! command -v pm2 &> /dev/null
then
    echo "📦 Installing PM2..."
    sudo npm install -g pm2
fi

# -----------------------------
# FRONTEND DEPLOYMENT
# -----------------------------
echo "--------------------------------------"
echo "🌐 Deploying Frontend"
echo "--------------------------------------"

if [ ! -d "$FRONTEND_DIR" ]; then
    echo "❌ Frontend directory not found!"
    exit 1
fi

# Backup
if [ -d "$DEST_DIR" ] && [ "$(ls -A $DEST_DIR)" ]; then
    echo "📁 Taking backup..."
    sudo cp -r $DEST_DIR $BACKUP_DIR
fi

# Deploy
sudo rm -rf ${DEST_DIR:?}/*
sudo cp -r $FRONTEND_DIR/* $DEST_DIR/
sudo chown -R www-data:www-data $DEST_DIR

# Restart Nginx
echo "🔄 Restarting Nginx..."
sudo systemctl restart $SERVICE

# -----------------------------
# BACKEND DEPLOYMENT
# -----------------------------
echo "--------------------------------------"
echo "⚙️ Deploying Backend"
echo "--------------------------------------"

if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Backend directory not found!"
    exit 1
fi

cd $BACKEND_DIR

# Install dependencies
npm install || true

# Restart backend using PM2
pm2 delete backend-app || true
pm2 start server.js --name backend-app
pm2 save

# -----------------------------
# HEALTH CHECK
# -----------------------------
echo "--------------------------------------"
echo "🌐 Checking Services"
echo "--------------------------------------"

sudo systemctl status $SERVICE --no-pager
pm2 status

echo "--------------------------------------"
echo "✅ Full Deployment Successful"
echo "--------------------------------------"
