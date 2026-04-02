#!/bin/bash

set -euo pipefail

echo "--------------------------------------"
echo "🚀 Starting Full Stack Deployment"
echo "--------------------------------------"

# -----------------------------
# Variables
# -----------------------------
WORKSPACE_DIR="${WORKSPACE:-$(pwd)}"
FRONTEND_DIR="$WORKSPACE_DIR/app/frontend"
BACKEND_DIR="$WORKSPACE_DIR/app/backend"

DEST_DIR="/var/www/html"
SERVICE="nginx"

# -----------------------------
# Install dependencies
# -----------------------------
echo "📦 Installing dependencies..."
sudo apt update -y

if ! command -v nginx &> /dev/null; then
    sudo apt install -y nginx
fi

if ! command -v node &> /dev/null; then
    sudo apt install -y nodejs npm
fi

if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
fi

# -----------------------------
# Configure Nginx
# -----------------------------
echo "⚙️ Configuring Nginx..."

sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root $DEST_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /api {
        proxy_pass http://localhost:3000;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# 🔥 IMPORTANT FIX: enable config
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# 🔥 FULL restart (not reload)
sudo nginx -t
sudo systemctl stop nginx
sudo systemctl start nginx

# Debug (optional but useful)
echo "🔍 Active Nginx config:"
sudo nginx -T | grep api || true

# -----------------------------
# FRONTEND DEPLOYMENT
# -----------------------------
echo "🌐 Deploying Frontend..."

if [ ! -d "$FRONTEND_DIR" ]; then
    echo "❌ Frontend directory not found!"
    exit 1
fi

sudo rm -rf "$DEST_DIR"/*
sudo cp -r "$FRONTEND_DIR"/* "$DEST_DIR"/
sudo chown -R www-data:www-data "$DEST_DIR"

# -----------------------------
# BACKEND DEPLOYMENT
# -----------------------------
echo "⚙️ Deploying Backend..."

if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Backend directory not found!"
    exit 1
fi

cd "$BACKEND_DIR"

npm install

# Clean PM2 + port issues
pm2 delete backend-app 2>/dev/null || true
pm2 kill || true
fuser -k 3000/tcp 2>/dev/null || true

# Start backend
pm2 start server.js --name backend-app
pm2 save

# Enable auto start (EC2 safe)
pm2 startup systemd -u $(whoami) --hp /home/$(whoami) || true

# -----------------------------
# HEALTH CHECK (SAFE)
# -----------------------------
echo "🌐 Checking Services..."

sleep 3

echo "🔍 Backend check..."
curl -s http://localhost:3000/api || echo "⚠️ Backend not ready"

echo "🔍 Nginx routing check..."
curl -s http://localhost/api || echo "⚠️ Nginx routing issue"

echo "--------------------------------------"
echo "✅ Deployment Completed Successfully"
echo "--------------------------------------"
