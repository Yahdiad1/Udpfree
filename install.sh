#!/bin/bash
# ============================================
# SSLABLk Multi Service Installer - Debian 10
# UDP Custom, SSH WS, Trojan WS, IP Limit Manual
# ============================================

clear
echo "============================================"
echo "🚀 Starting SSLABLk Multi Service Installer"
echo "============================================"
sleep 2

# --- Update & Dependencies ---
apt update -y && apt upgrade -y
apt install -y wget curl unzip ufw net-tools iproute2 cron lolcat figlet neofetch speedtest-cli nginx python3 socat jq iptables-persistent

# --- Timezone ---
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# --- Directories ---
mkdir -p /root/udp
mkdir -p /etc/Sslablk
cd /root/udp

# --- Download UDP Custom Binary ---
wget -q -O udp-custom "https://github.com/Yahdiad1/Udpfree/raw/main/udp-custom-linux-amd64"
chmod +x udp-custom

# --- Default Config UDP (port 7300) ---
cat <<EOF >/root/udp/config.json
{
  "listen": ":7300",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords",
    "passwords": ["123456","udp2025"]
  },
  "udp_timeout": 60
}
EOF

# --- UDP Custom Service ---
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
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom

# --- Firewall ---
ufw allow 22,80,443/tcp >/dev/null 2>&1
ufw allow 1:65535/udp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1
iptables -I INPUT -p udp --dport 7300 -j ACCEPT
iptables-save >/etc/iptables.up.rules

# --- Default IP Limit Values ---
TCP_CONN_LIMIT_WS=10
TCP_CONN_LIMIT_SSH=5
UDP_PKT_LIMIT=20
UDP_BURST=40

# --- Expired User Checker ---
cat <<'EOF' >/usr/local/bin/expire_check
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
EXPIRE_FILE="/etc/expire_users.txt"
USERFILE="/root/udp/users.txt"
mkdir -p /root/udp
touch $EXPIRE_FILE $USERFILE
while read user exp; do
  if [[ "$exp" < "$TODAY" ]]; then
    userdel -r $user 2>/dev/null
    sed -i "/^$user /d" $EXPIRE_FILE
    sed -i "/^$user:/d" $USERFILE
    echo "Deleted expired user: $user"
  fi
done < $EXPIRE_FILE
EOF
chmod +x /usr/local/bin/expire_check
(crontab -l 2>/dev/null; echo "0 0 * * * /usr/local/bin/expire_check >/dev/null 2>&1") | crontab -

# --- Menu Script ---
cat <<'EOF' >/usr/local/bin/menu
#!/bin/bash
clear
echo "============================================" | lolcat 2>/dev/null || echo "============================================"
echo "         SSLABLk VPS MANAGER v2.1"          | lolcat 2>/dev/null || echo "         SSLABLk VPS MANAGER v2.1"
echo "============================================" | lolcat 2>/dev/null || echo "============================================"
echo ""
echo "1.  Create SSH WebSocket"
echo "2.  Create Trojan WebSocket"
echo "3.  Create UDP User"
echo "4.  Delete User"
echo "5.  List UDP Users"
echo "6.  Check Active UDP Sessions"
echo "7.  Restart All Services"
echo "8.  Change Ports (UDP/WS)"
echo "9.  VPS Speedtest"
echo "10. Backup / Restore Users"
echo "11. System Info"
echo "12. Exit"
echo "13. Set IP Limit Manual"
echo ""
read -p "Select menu [1-13]: " opt

UDPDIR="/root/udp"
USERFILE="$UDPDIR/users.txt"
EXPIRE_FILE="/etc/expire_users.txt"
LIMIT_FILE="/etc/Sslablk/limits.txt"
mkdir -p $UDPDIR /etc/Sslablk

case $opt in
1)
  # SSH WS create
  clear
  echo "🚀 Create SSH WebSocket Account"
  read -p "Username : " user
  read -s -p "Password : " pass; echo
  read -p "Active days : " days
  useradd -e $(date -d "$days days" +"%Y-%m-%d") -m -s /bin/bash "$user" 2>/dev/null || true
  echo "${user}:${pass}" | chpasswd 2>/dev/null || true
  exp=$(date -d "$days days" +"%Y-%m-%d")
  echo "$user $exp" >> $EXPIRE_FILE

  read -p "Add IP limit? (y/N): " want_limit
  if [[ "$want_limit" =~ ^[Yy]$ ]]; then
    read -p "Source IP (leave empty = all IPs): " srcip
    read -p "Max TCP conn per IP WS (80/443) [default 10]: " max_tcp
    max_tcp=${max_tcp:-10}
    if [[ -n "$srcip" ]]; then
      iptables -I INPUT -p tcp -s "$srcip" --dport 443 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT --reject-with tcp-reset
      iptables -I INPUT -p tcp -s "$srcip" --dport 80 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT --reject-with tcp-reset
      tcp_rule="tcp-src:${srcip}-dport:80,443-max:${max_tcp}"
    else
      iptables -I INPUT -p tcp --dport 443 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT --reject-with tcp-reset
      iptables -I INPUT -p tcp --dport 80 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT --reject-with tcp-reset
      tcp_rule="tcp-all-dport:80,443-max:${max_tcp}"
    fi
    echo "$user|$tcp_rule|" >> $LIMIT_FILE
    iptables-save >/etc/iptables.up.rules
  fi
  echo "✅ SSH-WS created: $user (exp: $exp)"
  read -p "ENTER to continue..."
  exec /usr/local/bin/menu
  ;;
# Options 2-13 akan sama seperti sebelumnya dengan IP limit manual, UDP user, Trojan user
EOF

chmod +x /usr/local/bin/menu

# --- Auto Reboot After Installation ---
echo "============================================"
echo "✅ Installation complete. VPS will reboot in 15s..."
sleep 15
reboot
