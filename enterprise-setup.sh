#!/bin/bash
# LanguageTool Enterprise Setup Script
# Run with: sudo bash enterprise-setup.sh

set -e

echo "=== LanguageTool Enterprise Setup ==="
echo ""

# Phase 1: Create additional service instances
echo "[1/6] Creating additional service instances..."

# Create service files for instances 2 and 3
cat > /etc/systemd/system/languagetool-2.service << 'EOF'
[Unit]
Description=LanguageTool Server Instance 2
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/opt/languagetool-full
ExecStart=/usr/bin/java -Xms2g -Xmx4g -XX:+UseG1GC -XX:+UseStringDeduplication -XX:MaxGCPauseMillis=200 -cp languagetool-server.jar org.languagetool.server.HTTPServer --port 8082 --config /opt/languagetool/server/languagetool.conf --allow-origin "*"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/languagetool-3.service << 'EOF'
[Unit]
Description=LanguageTool Server Instance 3
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/opt/languagetool-full
ExecStart=/usr/bin/java -Xms2g -Xmx4g -XX:+UseG1GC -XX:+UseStringDeduplication -XX:MaxGCPauseMillis=200 -cp languagetool-server.jar org.languagetool.server.HTTPServer --port 8083 --config /opt/languagetool/server/languagetool.conf --allow-origin "*"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start new instances
systemctl daemon-reload
systemctl enable languagetool-2 languagetool-3
systemctl start languagetool-2 languagetool-3

echo "✓ Instances 2 and 3 created and started"

# Phase 2: Create custom rules directory
echo "[2/6] Creating custom rules directory..."
mkdir -p /opt/languagetool/custom-rules
chown deploy:deploy /opt/languagetool/custom-rules
echo "✓ Custom rules directory created"

# Phase 3: Install Redis (for caching)
echo "[3/6] Installing Redis..."
apt update -qq
apt install -y redis-server
systemctl enable redis-server
systemctl start redis-server
echo "✓ Redis installed and running"

# Phase 4: Add rate limiting to nginx.conf
echo "[4/6] Adding rate limiting to nginx.conf..."
# Add limit_req_zone to nginx.conf inside http block
if ! grep -q "limit_req_zone" /etc/nginx/nginx.conf; then
    sed -i '/http {/a\    limit_req_zone $binary_remote_addr zone=lt_limit:10m rate=20r/s;' /etc/nginx/nginx.conf
    echo "✓ Rate limiting added to nginx.conf"
else
    echo "✓ Rate limiting already configured"
fi

# Phase 5: Create nginx load balancer config
echo "[5/6] Creating nginx load balancer config..."
cat > /etc/nginx/sites-available/languagetool-lb << 'EOF'
upstream languagetool_backend {
    least_conn;
    server 127.0.0.1:8081;
    server 127.0.0.1:8082;
    server 127.0.0.1:8083;
    keepalive 32;
}

server {
    listen 8080;
    server_name _;

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss;
    gzip_comp_level 5;
    add_header X-Content-Type-Options "nosniff" always;

    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    location /v2/ {
        limit_req zone=lt_limit burst=50 nodelay;
        proxy_pass http://languagetool_backend;
    }

    location /health {
        access_log off;
        proxy_pass http://languagetool_backend;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/languagetool-lb /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
echo "✓ Nginx load balancer configured"

# Phase 6: Create logging directory
echo "[6/6] Creating logging directory..."
mkdir -p /var/log/languagetool
chown deploy:deploy /var/log/languagetool
echo "✓ Logging directory created"

# Final status check
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Summary:"
echo "  - 3 LanguageTool instances running (ports 8081-8083)"
echo "  - Nginx load balancer on port 8080"
echo "  - Redis cache installed"
echo "  - Rate limiting: 20 requests/sec per IP"
echo "  - Custom rules directory: /opt/languagetool/custom-rules/"
echo "  - Logs directory: /var/log/languagetool/"
echo ""

# Check services
echo "=== Service Status ==="
for svc in languagetool languagetool-2 languagetool-3 redis-server; do
    if systemctl is-active --quiet $svc; then
        echo "✓ $svc: running"
    else
        echo "✗ $svc: not running"
    fi
done
echo ""

# Test endpoints
echo "=== Testing Endpoints ==="
for port in 8081 8082 8083; do
    if curl -sf http://127.0.0.1:$port/v2/languages > /dev/null 2>&1; then
        echo "✓ Instance on port $port: responding"
    else
        echo "✗ Instance on port $port: not responding"
    fi
done

echo ""
echo "To add custom rules:"
echo "  1. Copy rule XML to /opt/languagetool/custom-rules/"
echo "  2. Restart: systemctl restart languagetool*"
