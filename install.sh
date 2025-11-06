#!/bin/bash
# =============================================
# SSLABLk VPS Full Menu v1.0
# Debian 10
# =============================================
UDPDIR="/root/udp"
USERFILE="$UDPDIR/users.txt"
EXPIRE_FILE="/etc/expire_users.txt"
LIMIT_FILE="/etc/Sslablk/limits.txt"
TROJAN_FILE="/etc/trojan_users.txt"

mkdir -p $UDPDIR /etc/Sslablk

while true; do
clear
echo "============================================"
echo "         SSLABLk VPS Manager Full"
echo "============================================"
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

case $opt in
1)
  clear
  echo "== Create SSH WebSocket =="
  read -p "Username: " user
  read -s -p "Password: " pass; echo
  read -p "Active days: " days
  useradd -e $(date -d "$days days" +"%Y-%m-%d") -m -s /bin/bash "$user" 2>/dev/null || true
  echo "${user}:${pass}" | chpasswd 2>/dev/null
  exp=$(date -d "$days days" +"%Y-%m-%d")
  echo "$user $exp" >> $EXPIRE_FILE
  read -p "Add IP limit? (y/N): " want_limit
  if [[ "$want_limit" =~ ^[Yy]$ ]]; then
    read -p "Source IP (empty=all): " srcip
    read -p "Max TCP connections (80/443, default 10): " max_tcp
    max_tcp=${max_tcp:-10}
    if [[ -n "$srcip" ]]; then
      iptables -I INPUT -p tcp -s "$srcip" --dport 443 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
      iptables -I INPUT -p tcp -s "$srcip" --dport 80 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
    else
      iptables -I INPUT -p tcp --dport 443 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
      iptables -I INPUT -p tcp --dport 80 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
    fi
    echo "$user|tcp-src:$srcip-max:$max_tcp" >> $LIMIT_FILE
  fi
  iptables-save >/etc/iptables.up.rules
  echo "✅ SSH WS created: $user (exp: $exp)"
  read -p "ENTER to continue..."
;;
2)
  clear
  echo "== Create Trojan WebSocket =="
  read -p "Label (username): " user
  read -p "Active days: " days
  uuid=$(cat /proc/sys/kernel/random/uuid)
  exp=$(date -d "$days days" +"%Y-%m-%d")
  echo "$user $uuid $exp" >> $TROJAN_FILE
  echo "$user $exp" >> $EXPIRE_FILE
  read -p "Add IP limit? (y/N): " want_limit
  if [[ "$want_limit" =~ ^[Yy]$ ]]; then
    read -p "Source IP (empty=all): " srcip
    read -p "Max TCP connections (443, default 5): " max_tcp
    max_tcp=${max_tcp:-5}
    if [[ -n "$srcip" ]]; then
      iptables -I INPUT -p tcp -s "$srcip" --dport 443 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
    else
      iptables -I INPUT -p tcp --dport 443 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
    fi
    echo "$user|tcp-src:$srcip-max:$max_tcp" >> $LIMIT_FILE
  fi
  iptables-save >/etc/iptables.up.rules
  echo "✅ Trojan WS created: $user (UUID:$uuid, exp:$exp)"
  read -p "ENTER to continue..."
;;
3)
  clear
  echo "== Create UDP User =="
  read -p "Username: " user
  read -s -p "Password: " pass; echo
  read -p "Active days: " days
  exp=$(date -d "$days days" +"%Y-%m-%d")
  echo "$user:$pass:$exp" >> $USERFILE
  echo "$user $exp" >> $EXPIRE_FILE
  read -p "Add IP limit? (y/N): " want_limit
  if [[ "$want_limit" =~ ^[Yy]$ ]]; then
    read -p "Source IP (empty=all): " srcip
    read -p "Max UDP packets/sec (7300, default 20): " max_udp
    max_udp=${max_udp:-20}
    read -p "UDP burst (default 40): " udp_burst
    udp_burst=${udp_burst:-40}
    if [[ -n "$srcip" ]]; then
      iptables -I INPUT -p udp -s "$srcip" --dport 7300 -m hashlimit --hashlimit-above "${max_udp}/second" --hashlimit-burst "$udp_burst" --hashlimit-mode srcip --hashlimit-name "udp_${user}" -j DROP
    else
      iptables -I INPUT -p udp --dport 7300 -m hashlimit --hashlimit-above "${max_udp}/second" --hashlimit-burst "$udp_burst" --hashlimit-mode srcip --hashlimit-name "udp_${user}" -j DROP
    fi
    echo "$user|udp-src:$srcip-max:$max_udp-burst:$udp_burst" >> $LIMIT_FILE
    iptables-save >/etc/iptables.up.rules
  fi
  echo "✅ UDP user $user created (exp:$exp)"
  read -p "ENTER to continue..."
;;
4)
  clear
  read -p "Username to delete: " user
  sed -i "/^$user:/d" $USERFILE 2>/dev/null
  sed -i "/^$user /d" $TROJAN_FILE 2>/dev/null
  sed -i "/^$user /d" $EXPIRE_FILE 2>/dev/null
  if id "$user" >/dev/null 2>&1; then userdel -r "$user" 2>/dev/null || true; fi
  # Remove IP limits
  if [ -f $LIMIT_FILE ]; then
    sed -i "/^$user|/d" $LIMIT_FILE
    iptables-save >/etc/iptables.up.rules
  fi
  echo "✅ User $user deleted"
  read -p "ENTER to continue..."
;;
5)
  clear
  echo "== List UDP Users =="
  cat $USERFILE
  read -p "ENTER to continue..."
;;
6)
  clear
  echo "== Active UDP Sessions =="
  netstat -anu | grep 7300 || echo "No UDP session active"
  read -p "ENTER to continue..."
;;
7)
  systemctl restart udp-custom
  echo "✅ Services restarted"
  read -p "ENTER to continue..."
;;
8)
  clear
  echo "⚙️ Change Ports (manual edit config.json)"
  read -p "ENTER to continue..."
;;
9)
  clear
  speedtest-cli
  read -p "ENTER to continue..."
;;
10)
  clear
  echo "⚠️ Backup / Restore not implemented"
  read -p "ENTER to continue..."
;;
11)
  clear
  neofetch
  read -p "ENTER to continue..."
;;
12)
  exit
;;
13)
  clear
  read -p "Username: " user
  read -p "Source IP (empty=all): " srcip
  read -p "Max TCP (leave empty to skip): " max_tcp
  read -p "Max UDP (leave empty to skip): " max_udp
  read -p "UDP burst (default 40): " udp_burst
  udp_burst=${udp_burst:-40}

  if [[ -n "$max_tcp" ]]; then
    if [[ -n "$srcip" ]]; then
      iptables -I INPUT -p tcp -s "$srcip" --dport 80 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
      iptables -I INPUT -p tcp -s "$srcip" --dport 443 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
    else
      iptables -I INPUT -p tcp --dport 80 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
      iptables -I INPUT -p tcp --dport 443 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
    fi
  fi

  if [[ -n "$max_udp" ]]; then
    if [[ -n "$srcip" ]]; then
      iptables -I INPUT -p udp -s "$srcip" --dport 7300 -m hashlimit --hashlimit-above "${max_udp}/second" --hashlimit-burst "$udp_burst" --hashlimit-mode srcip --hashlimit-name "udp_${user}" -j DROP
    else
      iptables -I INPUT -p udp --dport 7300 -m hashlimit --hashlimit-above "${max_udp}/second" --hashlimit-burst "$udp_burst" --hashlimit-mode srcip --hashlimit-name "udp_${user}" -j DROP
    fi
    iptables-save >/etc/iptables.up.rules
  fi
  echo "✅ IP limit set for $user"
  read -p "ENTER to continue..."
;;
*)
  echo "Invalid option"
  sleep 1
;;
esac
done
