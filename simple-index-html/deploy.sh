#!/bin/bash

set -euo pipefail

echo "🚀 Starting Deployment on EC2..."

WORKSPACE_DIR="${WORKSPACE:-$(pwd)}"
FRONTEND_DIR="$WORKSPACE_DIR/app/frontend"
BACKEND_DIR="$WORKSPACE_DIR/app/backend"

DEST_DIR="/var/www/html"
SERVICE="nginx"

# -----------------------------
# Install dependencies
# -----------------------------
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
    listen 80;
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
    }
}
EOF

sudo nginx -t
sudo systemctl restart nginx

# -----------------------------
# Deploy frontend
# -----------------------------
sudo rm -rf "$DEST_DIR"/*
sudo cp -r "$FRONTEND_DIR"/* "$DEST_DIR"/

# -----------------------------
# Deploy backend
# -----------------------------
cd "$BACKEND_DIR"

npm install

pm2 delete backend-app 2>/dev/null || true
pm2 start server.js --name backend-app
pm2 save

# -----------------------------
# Enable PM2 auto start (EC2 fix)
# -----------------------------
pm2 startup systemd -u $(whoami) --hp /home/$(whoami)

# -----------------------------
# Health check
# -----------------------------
echo "Testing..."

curl http://localhost:3000/api
curl http://localhost/api

echo "✅ Deployment Complete on EC2"
