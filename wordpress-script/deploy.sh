#!/bin/bash

# Configuration
PORT=8081
WP_DIR="wordpress"
SQLITE_PLUGIN_URL="https://downloads.wordpress.org/plugin/sqlite-database-integration.zip"

# Download WordPress if not already present
if [ ! -d "$WP_DIR" ]; then
    echo "Downloading WordPress..."
    curl -L -O https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    rm latest.tar.gz
fi

cd "$WP_DIR"

# Install SQLite database plugin for WordPress to avoid MySQL dependency in this environment
if [ ! -d "wp-content/plugins/sqlite-database-integration" ]; then
    echo "Installing SQLite Database Integration plugin..."
    curl -L -o sqlite-plugin.zip "$SQLITE_PLUGIN_URL"
    unzip -q sqlite-plugin.zip -d wp-content/plugins/
    rm sqlite-plugin.zip
    # Move the db.copy to wp-content/db.php
    cp wp-content/plugins/sqlite-database-integration/db.copy wp-content/db.php
fi

# Create wp-config.php if it doesn't exist
if [ ! -f "wp-config.php" ]; then
    echo "Configuring wp-config.php..."
    cp wp-config-sample.php wp-config.php

    # Use a more portable way to replace strings in wp-config.php
    python3 -c "
import sys
content = open('wp-config.php').read()
content = content.replace('database_name_here', 'wordpress')
content = content.replace('username_here', 'wordpress_user')
content = content.replace('password_here', 'wordpress_password')
open('wp-config.php', 'w').write(content)
"
fi

# Stop existing process on port
PID=$(lsof -t -i :$PORT)
if [ ! -z "$PID" ]; then
    echo "Stopping existing process on port $PORT (PID: $PID)..."
    kill $PID
    sleep 1
fi

# Start PHP server
php -S localhost:$PORT > ../wp_server.log 2>&1 &

echo "WordPress is being deployed at http://localhost:$PORT using PHP built-in server and SQLite."
