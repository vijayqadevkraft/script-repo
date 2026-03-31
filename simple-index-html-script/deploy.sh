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
    <p>This page was deployed using a script (PHP built-in server).</p>
</body>
</html>
EOF

# Port to use
PORT=8080

# Check if something is already running on the port and stop it
PID=$(lsof -t -i :$PORT)
if [ ! -z "$PID" ]; then
    echo "Stopping existing process on port $PORT (PID: $PID)..."
    kill $PID
    sleep 1
fi

# Run PHP built-in server to serve the index.html
php -S localhost:$PORT > php_server.log 2>&1 &

echo "Simple index.html is being served at http://localhost:$PORT using PHP built-in server"
