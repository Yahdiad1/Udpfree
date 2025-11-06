#!/bin/bash
# ============================================
# UDP Custom Installer by Yahdiad1 / SSLABLk
# Fixed & Improved by Yhds
# ============================================
echo "============================================"
echo "🚀 Starting UDP Custom Installer..."
echo "============================================"
sleep 2

# Update & Install Dependensi
apt update -y && apt upgrade -y
apt install -y wget curl unzip ufw net-tools iproute2 cron

# Create Main Directory
mkdir -p /root/udp
cd /root/udp

# ============================================
# Banner
# ============================================
clear
echo "============================================"
echo "         UDP CUSTOM INSTALLER"
echo "============================================"
echo " UDP Free Net | UDP For VPN | SSLABLk"
echo "============================================"
sleep 2

# ============================================
# Set Timezone
# ============================================
echo "[*] Setting timezone to Asia/Jakarta..."
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# ============================================
# Install UDP Custom Binary
# ============================================
echo "[*] Downloading UDP Custom binary..."
wget -q -O /root/udp/udp-custom "https://github.com/Yahdiad1/Udpfree/raw/main/udp-custom-linux-amd64"
chmod +x /root/udp/udp-custom

echo "[*] Downloading default config..."
wget -q -O /root/udp/config.json "https://raw.githubusercontent.com/Yahdiad1/Udpfree/main/config.json"
chmod 644 /root/udp/config.json

# ============================================
# Create systemd Service
# ============================================
cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Service
After=network.target

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server
WorkingDirectory=/root/udp/
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

# ============================================
# Firewall & Port Setup
# ============================================
echo "[*] Opening all UDP ports (1–65535)..."
ufw allow 1:65535/udp >/dev/null 2>&1
ufw allow 22/tcp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1

iptables -I INPUT -p udp --dport 1:65535 -j ACCEPT
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables-save > /etc/iptables.up.rules

# ============================================
# Start UDP Custom Service
# ============================================
echo "[*] Starting UDP Custom service..."
systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom

# ============================================
# Auto Restart + Auto Reboot Cron
# ============================================
echo "[*] Setting up cron jobs..."
(crontab -l 2>/dev/null; echo "*/5 * * * * systemctl restart udp-custom >/dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 5 * * * /sbin/reboot >/dev/null 2>&1") | crontab -

service cron restart

# ============================================
# Display Info
# ============================================
clear
IP=$(hostname -I | awk '{print $1}')
STATUS=$(systemctl is-active udp-custom)

echo "============================================"
echo "✅ UDP Custom Installed Successfully!"
echo "============================================"
echo "Service Name : udp-custom"
echo "Status       : $STATUS"
echo "VPS IP       : $IP"
echo "Ports Open   : UDP 1–65535"
echo "Binary Path  : /root/udp/udp-custom"
echo "Config Path  : /root/udp/config.json"
echo "Auto Restart : Every 5 minutes"
echo "Auto Reboot  : 05:00 AM Daily"
echo "============================================"
echo "GitHub  : Yahdiad1"
echo "Telegram: @aris"
echo "============================================"

echo ""
echo "[*] Checking UDP Listening Ports..."
sleep 2
netstat -anu | grep -E 'udp' || echo "⚠️ No UDP process found (wait a few seconds or check config)."

echo ""
echo "Installation complete! Reboot recommended."
echo "To check service: systemctl status udp-custom"
echo "============================================"
echo reboot
reboot
