#!/bin/bash

# LanguageTool Server Setup Script for Ubuntu/Debian
# Run as: sudo bash setup-server.sh

set -e

echo "=== LanguageTool Server Setup ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Update system
echo "Updating system..."
apt update && apt upgrade -y

# Install Java 17
echo "Installing Java 17..."
apt install -y openjdk-17-jdk redis-server nginx certbot python3-certbot-nginx

# Create LanguageTool directory
echo "Setting up directories..."
mkdir -p /opt/languagetool
cd /opt/languagetool

# Note: You need to upload the JAR file to this directory
# You can download from: https://languagetool.org/download/LanguageTool-stable.zip
# Or build from source: mvn clean package -DskipTests

echo "Directory created at /opt/languagetool"
echo "Please upload languagetool-server.jar to this directory"

# Copy systemd service
echo "Installing systemd service..."
cp /path/to/languagetool.service /etc/systemd/system/
systemctl daemon-reload

# Copy nginx config
echo "Installing nginx configuration..."
cp /path/to/nginx-languagetool.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/nginx-languagetool.conf /etc/nginx/sites-enabled/

# Test nginx config
nginx -t

# Enable and start services
echo "Starting services..."
systemctl enable redis-server
systemctl enable nginx
systemctl enable languagetool

systemctl start redis-server
systemctl start languagetool
systemctl restart nginx

echo "=== Setup Complete ==="
echo ""
echo "Check status with:"
echo "  systemctl status languagetool"
echo "  systemctl status nginx"
echo ""
echo "View logs with:"
echo "  journalctl -u languagetool -f"
echo "  tail -f /var/log/nginx/error.log"
