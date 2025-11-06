#!/bin/bash
# ============================================
# SSLABLk Installer (UDP + SSH-WS + Trojan-WS)
# For Debian 10 by Yhds
# ============================================

clear
echo "============================================"
echo "🚀 Starting SSLABLk Installer (UDP + WS)"
echo "============================================"
sleep 2

# Update & Upgrade
apt update -y && apt upgrade -y
apt install -y wget curl unzip socat cron net-tools nginx iptables iproute2 ufw

# Set timezone
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# Create main directory
mkdir -p /etc/Sslablk/system
mkdir -p /root/udp
mkdir -p /usr/local/etc/xray

# ============================================
# Install UDP Custom
# ============================================
echo "[*] Installing UDP Custom..."
wget -q -O /root/udp/udp-custom "https://github.com/Yahdiad1/Udpfree/raw/main/udp-custom-linux-amd64"
chmod +x /root/udp/udp-custom
wget -q -O /root/udp/config.json "https://raw.githubusercontent.com/Yahdiad1/Udpfree/main/config.json"

cat <<EOF >/etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Service
After=network.target

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server
WorkingDirectory=/root/udp/
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom

# ============================================
# Firewall
# ============================================
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 1:65535/udp
ufw --force enable
iptables -I INPUT -p udp --dport 1:65535 -j ACCEPT
iptables-save > /etc/iptables.up.rules

# ============================================
# Install Xray Core (for WS + TLS)
# ============================================
echo "[*] Installing Xray..."
bash <(curl -fsSL https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

# Create random domain via sslip.io
IP=$(hostname -I | awk '{print $1}')
DOMAIN="${IP//./-}.sslip.io"

# Generate self-signed certificate
mkdir -p /etc/xray
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/xray/private.key -out /etc/xray/cert.crt \
  -subj "/CN=$DOMAIN"

# ============================================
# Xray Config (SSH WS + Trojan WS)
# ============================================
UUID=$(cat /proc/sys/kernel/random/uuid)
cat <<EOF >/usr/local/etc/xray/config.json
{
  "inbounds": [
    {
      "port": 80,
      "protocol": "vless",
      "settings": { "clients": [{ "id": "$UUID", "level": 0 }] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/ssh" } }
    },
    {
      "port": 443,
      "protocol": "trojan",
      "settings": { "clients": [{ "password": "$UUID" }] },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": { "certificates": [{ "certificateFile": "/etc/xray/cert.crt", "keyFile": "/etc/xray/private.key" }] },
        "wsSettings": { "path": "/trojan" }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

systemctl enable xray
systemctl restart xray

# ============================================
# Nginx Config for WebSocket
# ============================================
cat <<EOF >/etc/nginx/sites-available/default
server {
    listen 80;
    server_name $DOMAIN;
    location /ssh {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

systemctl restart nginx

# ============================================
# Auto Restart + Auto Reboot
# ============================================
(crontab -l 2>/dev/null; echo "*/5 * * * * systemctl restart udp-custom >/dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 5 * * * /sbin/reboot >/dev/null 2>&1") | crontab -
service cron restart

# ============================================
# Install Menu
# ============================================
wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/Yahdiad1/Udpfree/main/menu"
chmod +x /usr/local/bin/menu
ln -sf /usr/local/bin/menu /bin/menu

# ============================================
# Final Info
# ============================================
clear
echo "============================================"
echo "✅ Install Success (Debian 10)"
echo "============================================"
echo "UDP Port     : 1–65535"
echo "SSH WS Path  : /ssh"
echo "Trojan WS    : /trojan"
echo "Domain       : $DOMAIN"
echo "UUID         : $UUID"
echo "Binary Path  : /root/udp/udp-custom"
echo "Config Path  : /root/udp/config.json"
echo "Menu Command : menu"
echo "============================================"

echo ""
echo "✅ Instalasi selesai! VPS akan reboot otomatis dalam 5 detik..."
sleep 5
reboot
