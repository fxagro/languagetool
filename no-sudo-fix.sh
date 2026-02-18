#!/bin/bash

# LanguageTool 502 Error Fix Script (No sudo required)
# Run as: bash no-sudo-fix.sh

set -e

echo "=== LanguageTool 502 Error Fix ==="

# Create directory in user's home
rm -rf ~/languagetool
mkdir -p ~/languagetool
cd ~/languagetool

# Download and extract LanguageTool
echo "Downloading LanguageTool..."
wget -q https://languagetool.org/download/LanguageTool-stable.zip
unzip -q LanguageTool-stable.zip
mv LanguageTool-* server
rm LanguageTool-stable.zip

# Create systemd service (will need sudo at end)
cat > languagetool.service << 'EOF'
[Unit]
Description=LanguageTool Server
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/home/deploy/languagetool/server
ExecStart=/usr/bin/java -Xms512m -Xmx2g -cp "languagetool-server.jar:libs/*" org.languagetool.server.HTTPServer --port 8081 --allow-origin "*" --public
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create nginx configuration
cat > nginx-languagetool.conf << 'EOF'
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

echo "=== Files Created ==="
echo "1. ~/languagetool/languagetool.service (systemd service)"
echo "2. ~/languagetool/nginx-languagetool.conf (nginx config)"
echo "3. ~/languagetool/server/ (LanguageTool files)"
echo ""
echo "=== Now run these commands as root ==="
echo "sudo cp ~/languagetool/languagetool.service /etc/systemd/system/"
echo "sudo cp ~/languagetool/nginx-languagetool.conf /etc/nginx/sites-available/"
echo "sudo rm -f /etc/nginx/sites-enabled/default"
echo "sudo ln -sf /etc/nginx/sites-available/nginx-languagetool.conf /etc/nginx/sites-enabled/"
echo "sudo nginx -t"
echo "sudo systemctl daemon-reload"
echo "sudo systemctl enable languagetool"
echo "sudo systemctl start languagetool"
echo "sudo systemctl restart nginx"
echo ""
echo "=== Then test ==="
echo "curl http://127.0.0.1:8081/v2/languages"
echo "curl -I http://vmi3028068.contaboserver.net/"
