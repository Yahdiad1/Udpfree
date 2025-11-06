#!/bin/bash
# ============================================
# SSLABLk Multi Service Installer
# Debian 10 Compatible
# ============================================

clear
echo "============================================"
echo "🚀 Starting SSLABLk Multi Service Installer"
echo "============================================"
sleep 2

# --- Update & Dependencies ---
apt update -y && apt upgrade -y
apt install -y wget curl unzip ufw net-tools iproute2 cron lolcat figlet neofetch speedtest-cli nginx python3 socat jq

# --- Timezone ---
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# --- Directories ---
mkdir -p /root/udp
cd /root/udp

# --- Download UDP Custom Binary ---
wget -q -O udp-custom "https://github.com/Yahdiad1/Udpfree/raw/main/udp-custom-linux-amd64"
chmod +x udp-custom

# --- Default Config ---
wget -q -O config.json "https://raw.githubusercontent.com/Yahdiad1/Udpfree/main/config.json"

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

# --- Firewall ---
ufw allow 1:65535/udp >/dev/null 2>&1
ufw allow 22,80,443/tcp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1
iptables -I INPUT -p udp --dport 1:65535 -j ACCEPT
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables-save >/etc/iptables.up.rules

# --- Systemd Enable ---
systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom

# --- Create Expired Checker ---
cat <<EOF >/usr/local/bin/expire_check
#!/bin/bash
TODAY=\$(date +%Y-%m-%d)
EXPIRE_FILE="/etc/expire_users.txt"
if [ -f \$EXPIRE_FILE ]; then
  while read user exp; do
    if [[ "\$exp" < "\$TODAY" ]]; then
      userdel -r \$user 2>/dev/null
      sed -i "/^$user /d" \$EXPIRE_FILE
      sed -i "/^$user:/d" /root/udp/users.txt
      echo "Deleted expired user: \$user"
    fi
  done < \$EXPIRE_FILE
fi
EOF

chmod +x /usr/local/bin/expire_check
(crontab -l 2>/dev/null; echo "0 0 * * * /usr/local/bin/expire_check >/dev/null 2>&1") | crontab -

# --- Create Menu File ---
cat <<'EOF' >/usr/local/bin/menu
#!/bin/bash
clear
echo "============================================" | lolcat 2>/dev/null || echo "============================================"
echo "         YHDS VPS MANAGER v2.0"            | lolcat 2>/dev/null || echo "         SSLABLk VPS MANAGER v2.0"
echo "============================================" | lolcat 2>/dev/null || echo "============================================"
echo ""
echo "1.  Create SSH WebSocket"
echo "2.  Create Trojan WebSocket"
echo "3.  Create UDP User"
echo "4.  Delete UDP User"
echo "5.  List UDP Users"
echo "6.  Check Active UDP Sessions"
echo "7.  Restart All Services"
echo "8.  Change Ports (UDP/WS)"
echo "9.  VPS Speedtest"
echo "10. Backup / Restore Users"
echo "11. System Info"
echo "12. Exit"
echo ""
read -p "Select menu [1-12]: " opt

UDPDIR="/root/udp"
USERFILE="$UDPDIR/users.txt"
EXPIRE_FILE="/etc/expire_users.txt"
mkdir -p $UDPDIR

case $opt in
1)
    clear
    echo "🚀 Create SSH WebSocket Account"
    read -p "Username : " user
    read -p "Password : " pass
    read -p "Active days : " days
    useradd -e $(date -d "$days days" +"%Y-%m-%d") -m -s /bin/bash $user >/dev/null 2>&1
    echo "$user:$pass" | chpasswd
    exp=$(date -d "$days days" +"%Y-%m-%d")
    echo "$user $exp" >> $EXPIRE_FILE
    echo "✅ SSH WS Created | User: $user | Pass: $pass | Exp: $exp"
    ;;
2)
    clear
    echo "⚡ Create Trojan WebSocket"
    read -p "Username : " user
    read -p "Active days : " days
    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp=$(date -d "$days days" +"%Y-%m-%d")
    echo "$user $uuid $exp" >> /etc/trojan_users.txt
    echo "✅ Trojan WS Created | User: $user | UUID: $uuid | Exp: $exp"
    ;;
3)
    clear
    echo "➕ Create UDP User"
    read -p "Username : " user
    read -p "Password : " pass
    read -p "Active days : " days
    exp=$(date -d "$days days" +"%Y-%m-%d")
    echo "$user:$pass:$exp" >> $USERFILE
    echo "$user $exp" >> $EXPIRE_FILE
    echo "✅ UDP User Added | $user | Exp: $exp"
    ;;
4)
    clear
    echo "❌ Delete UDP User"
    read -p "Username : " user
    sed -i "/^$user:/d" $USERFILE
    sed -i "/^$user /d" $EXPIRE_FILE
    echo "User $user deleted."
    ;;
5)
    clear
    echo "📜 List UDP Users"
    column -t -s ":" $USERFILE
    ;;
6)
    clear
    echo "🧠 Active UDP Sessions"
    netstat -anu | grep udp
    ;;
7)
    systemctl restart udp-custom nginx
    echo "✅ Services restarted"
    ;;
8)
    echo "⚙️ Change Ports (Coming Soon)"
    ;;
9)
    speedtest
    ;;
10)
    echo "💾 Backup/Restore (Coming Soon)"
    ;;
11)
    neofetch
    ;;
12)
    exit
    ;;
*)
    echo "Invalid Option!"
    ;;
esac
EOF

chmod +x /usr/local/bin/menu

# --- Auto Reboot ---
echo ""
echo "✅ Installation complete!"
echo "System will reboot in 10 seconds..."
sleep 10
reboot
