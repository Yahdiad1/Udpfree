#!/bin/bash
# ============================================
# UDP Custom Installer by Yahdiad1 / SSLABLk
# Fixed & Improved by ChatGPT
# ============================================

clear
echo "Updating & installing dependencies..."
apt update -y && apt upgrade -y
apt install -y lolcat figlet neofetch screenfetch unzip wget curl ufw

# Create main directory
mkdir -p /root/udp
cd /root/udp

# ============================================
# BANNER
# ============================================
clear
echo -e "          ░█▀▀▀█ ░█▀▀▀█ ░█─── ─█▀▀█ ░█▀▀█   ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ─▀▀▀▄▄ ─▀▀▀▄▄ ░█─── ░█▄▄█ ░█▀▀▄   ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█▄▄▄█ ░█▄▄▄█ ░█▄▄█ ░█─░█ ░█▄▄█   ─▀▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo "" | lolcat
echo "       🔹 UDP CUSTOM 🔹" | lolcat
echo "       🔹 UDP FREE NET 🔹" | lolcat
echo "       🔹 UDP FOR NET 🔹" | lolcat
sleep 3

# ============================================
# Timezone (Asia/Jakarta)
# ============================================
echo "Setting timezone to Asia/Jakarta (GMT+7)..."
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# ============================================
# Install UDP Custom binary
# ============================================
echo "Downloading UDP Custom binary..."
wget -q -O /root/udp/udp-custom "https://github.com/Yahdiad1/Udpfree/raw/main/udp-custom-linux-amd64"
chmod +x /root/udp/udp-custom

echo "Downloading default config..."
wget -q -O /root/udp/config.json "https://raw.githubusercontent.com/Yahdiad1/Udpfree/main/config.json"
chmod 644 /root/udp/config.json

# ============================================
# Create systemd service
# ============================================
if [ -z "$1" ]; then
cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Service by SSLABLk
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
else
cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Service by SSLABLk
After=network.target

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server -exclude $1
WorkingDirectory=/root/udp/
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF
fi

# ============================================
# Menu & Tools
# ============================================
echo "Installing menu tools..."
mkdir -p /etc/Sslablk
cd /etc/Sslablk
wget -q https://github.com/Yahdiad1/Udpfree/raw/main/system.zip -O system.zip
unzip -o system.zip >/dev/null 2>&1
cd /etc/Sslablk/system

chmod +x ChangeUser.sh Adduser.sh DelUser.sh Userlist.sh RemoveScript.sh torrent.sh
mv menu /usr/local/bin/
chmod +x /usr/local/bin/menu
rm -f /etc/Sslablk/system.zip

# ============================================
# Open All UDP Ports (1–65535)
# ============================================
echo "Opening UDP ports 1–65535..."
ufw allow 1:65535/udp >/dev/null 2>&1
ufw allow 22/tcp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1

# Iptables fallback (for non-UFW systems)
iptables -I INPUT -p udp --dport 1:65535 -j ACCEPT
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables-save > /etc/iptables.up.rules
netfilter-persistent save >/dev/null 2>&1 2>/dev/null || true

# ============================================
# Enable & Start Service
# ============================================
echo "Enabling and starting UDP Custom service..."
systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom

# ============================================
# Info
# ============================================
clear
echo "============================================" | lolcat
echo "✅ UDP Custom Installed Successfully!" | lolcat
echo "Service Name : udp-custom" | lolcat
echo "Binary Path  : /root/udp/udp-custom" | lolcat
echo "Config Path  : /root/udp/config.json" | lolcat
echo "Menu Command : menu" | lolcat
echo "Ports Open   : UDP 1–65535" | lolcat
echo "============================================" | lolcat
echo "GitHub  : Yahdiad1" | lolcat
echo "Telegram: @aris" | lolcat
echo "============================================" | lolcat
sleep 3
