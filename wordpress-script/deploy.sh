#!/bin/bash

# Create docker-compose.yml for WordPress and MySQL
cat <<EOF > docker-compose.yml
services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: wordpress_root_password
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress_user
      MYSQL_PASSWORD: wordpress_password

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    ports:
      - "8081:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress_user
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress

volumes:
  db_data:
EOF

# Start the services
docker compose up -d

echo "WordPress is being deployed at http://localhost:8081"
echo "It may take a minute for the database to initialize."
