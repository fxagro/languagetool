#!/bin/bash

# Complete LanguageTool Server Setup & Fix 502 Error
# Run as: sudo bash fix-502-complete.sh

set -e

echo "=== LanguageTool 502 Error Fix ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Function to check if service is running
check_service() {
    if systemctl is-active --quiet "$1"; then
        echo "✅ $1 is running"
        return 0
    else
        echo "❌ $1 is not running"
        return 1
    fi
}

# Function to check port
check_port() {
    if netstat -tlnp | grep ":$1 " > /dev/null; then
        echo "✅ Port $1 is listening"
        return 0
    else
        echo "❌ Port $1 is not listening"
        return 1
    fi
}

echo "Step 1: Installing dependencies..."
apt update
apt install -y openjdk-17-jdk wget unzip curl

echo "Step 2: Setting up LanguageTool directory..."
mkdir -p /opt/languagetool
cd /opt/languagetool

# Download if not exists
if [ ! -d "server" ]; then
    echo "Downloading LanguageTool..."
    wget -q https://languagetool.org/download/LanguageTool-stable.zip
    unzip -q LanguageTool-stable.zip
    mv LanguageTool-* server
    rm LanguageTool-stable.zip
fi

echo "Step 3: Creating systemd service..."
cat > /etc/systemd/system/languagetool.service << 'EOF'
[Unit]
Description=LanguageTool Server
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/opt/languagetool/server
ExecStart=/usr/bin/java -cp "languagetool-server.jar:libs/*" org.languagetool.server.HTTPServer --port 8081 --allow-origin "*"

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Step 4: Creating nginx configuration..."
cat > /etc/nginx/sites-available/languagetool << 'EOF'
server {
    listen 80;
    server_name vmi3028068.contaboserver.net;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Proxy to LanguageTool server
    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # API endpoints
    location /v2/ {
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8081;
        access_log off;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
EOF

echo "Step 5: Enabling configurations..."
# Remove default nginx site if exists
rm -f /etc/nginx/sites-enabled/default

# Enable our site
ln -sf /etc/nginx/sites-available/languagetool /etc/nginx/sites-enabled/

# Reload systemd
systemctl daemon-reload

echo "Step 6: Starting services..."
systemctl enable languagetool
systemctl start languagetool

# Wait for service to start
sleep 5

# Test nginx config
nginx -t

# Restart nginx
systemctl restart nginx

echo "Step 7: Testing services..."
echo ""
echo "=== SERVICE STATUS ==="
check_service languagetool
check_service nginx

echo ""
echo "=== PORT STATUS ==="
check_port 8081
check_port 80

echo ""
echo "=== API TEST ==="
if curl -s http://127.0.0.1:8081/v2/languages > /dev/null 2>&1; then
    echo "✅ LanguageTool API is responding"
else
    echo "❌ LanguageTool API is not responding"
fi

echo ""
echo "=== FINAL TEST ==="
if curl -s -I http://127.0.0.1/ | grep -q "200 OK"; then
    echo "✅ Local nginx is working"
else
    echo "❌ Local nginx is not working"
fi

echo ""
echo "=== SETUP COMPLETE ==="
echo ""
echo "🌐 Test your website: http://vmi3028068.contaboserver.net/"
echo ""
echo "📊 Check logs if still having issues:"
echo "  journalctl -u languagetool -f"
echo "  tail -f /var/log/nginx/error.log"
echo ""
echo "🔧 Manual commands if needed:"
echo "  systemctl restart languagetool"
echo "  systemctl restart nginx"
