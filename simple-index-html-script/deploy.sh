#!/bin/bash

# Create a simple index.html file
cat <<EOF > index.html
<!DOCTYPE html>
<html>
<head>
    <title>Simple Index Page</title>
</head>
<body>
    <h1>Hello from Simple Index Script!</h1>
    <p>This page was deployed using a script.</p>
</body>
</html>
EOF

# Stop and remove existing container if it exists
docker stop simple-web-container 2>/dev/null || true
docker rm simple-web-container 2>/dev/null || true

# Run Nginx container to serve the index.html
docker run -d \
  --name simple-web-container \
  -p 8080:80 \
  -v "$(pwd)/index.html:/usr/share/nginx/html/index.html:ro" \
  nginx

echo "Simple index.html is being served at http://localhost:8080"
