#!/bin/bash

# LanguageTool 502 Error Fix Script (Run directly on your Contabo server)
# Run as root: sudo bash direct-server-fix.sh

set -e

echo "=== LanguageTool 502 Error Fix ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Cleanup any existing LanguageTool files
rm -rf /opt/languagetool
mkdir -p /opt/languagetool
cd /opt/languagetool

# Download and extract LanguageTool
echo "Downloading LanguageTool..."
wget -q https://languagetool.org/download/LanguageTool-stable.zip
unzip -q LanguageTool-stable.zip
mv LanguageTool-* server
rm LanguageTool-stable.zip

# Set correct permissions
echo "Setting permissions..."
chown -R deploy:deploy /opt/languagetool

# Create systemd service
cat > /etc/systemd/system/languagetool.service << 'EOF'
[Unit]
Description=LanguageTool Server
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/opt/languagetool/server
ExecStart=/usr/bin/java -Xms512m -Xmx2g -cp "languagetool-server.jar:libs/*" org.languagetool.server.HTTPServer --port 8081 --allow-origin "*" --public
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create nginx configuration
cat > /etc/nginx/sites-available/languagetool << 'EOF'
server {
    listen 80;
    server_name vmi3028068.contaboserver.net;

    # Proxy settings
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
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /v2/ {
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Configure nginx
echo "Configuring nginx..."
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/languagetool /etc/nginx/sites-enabled/
nginx -t

# Enable and start services
echo "Starting services..."
systemctl daemon-reload
systemctl enable languagetool
systemctl start languagetool

# Wait for service to start
echo "Waiting for LanguageTool to start..."
sleep 10

# Test the server
echo "Testing LanguageTool API..."
if curl -s http://127.0.0.1:8081/v2/languages > /dev/null 2>&1; then
    echo "✅ LanguageTool API is responding"
else
    echo "❌ LanguageTool API is not responding"
    systemctl status languagetool
    exit 1
fi

# Restart nginx
systemctl restart nginx

# Test nginx
echo "Testing nginx..."
if curl -s -I http://127.0.0.1/ | grep -q "200 OK"; then
    echo "✅ nginx is working"
else
    echo "❌ nginx is not working"
    nginx -t
    systemctl status nginx
    exit 1
fi

echo "=== Fix Complete! ==="
echo ""
echo "🌐 Your website is now accessible at: http://vmi3028068.contaboserver.net/"
echo ""
echo "📊 Service Status:"
systemctl status languagetool
echo ""
systemctl status nginx
