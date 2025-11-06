#!/bin/bash
# =============================================
# SSLABLk VPS Full Menu v2.0
# Debian 10 / Ubuntu
# SSH WS, UDP, Trojan WS
# Password manual + IP limit manual
# =============================================

# Directories & Files
UDPDIR="/root/udp"
USERFILE="$UDPDIR/users.txt"
SSHFILE="/etc/Sslablk/ssh_users.txt"
TROJANFILE="/etc/trojan_users.txt"
LIMITFILE="/etc/Sslablk/limits.txt"
mkdir -p $UDPDIR /etc/Sslablk
touch $USERFILE $SSHFILE $TROJANFILE $LIMITFILE

# ---------- Functions ----------
create_ssh_ws(){
    clear
    echo "== Create SSH WebSocket =="
    read -p "Username: " user
    read -s -p "Password: " pass; echo
    read -p "Active days: " days
    useradd -m -s /bin/bash "$user" 2>/dev/null || true
    echo "${user}:${pass}" | chpasswd
    expire_date=$(date -d "$days days" +"%Y-%m-%d")
    chage -E $expire_date $user
    echo "$user $expire_date" >> $SSHFILE
    read -p "Add IP limit? (y/N): " limit
    if [[ "$limit" =~ ^[Yy]$ ]]; then
        read -p "Source IP (empty=all): " srcip
        read -p "Max TCP connections (default 10): " max_tcp
        max_tcp=${max_tcp:-10}
        if [[ -n "$srcip" ]]; then
            iptables -I INPUT -p tcp -s "$srcip" --dport 443 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
            iptables -I INPUT -p tcp -s "$srcip" --dport 80 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
        else
            iptables -I INPUT -p tcp --dport 443 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
            iptables -I INPUT -p tcp --dport 80 -m connlimit --connlimit-above "$max_tcp" --connlimit-mask 32 -j REJECT
        fi
        echo "$user|tcp-src:$srcip-max:$max_tcp" >> $LIMITFILE
    fi
    iptables-save >/etc/iptables.up.rules
    echo "✅ SSH WS created: $user (exp:$expire_date)"
    read -p "ENTER to continue..."
}

create_udp_user(){
    clear
    echo "== Create UDP User =="
    read -p "Username: " user
    read -s -p "Password: " pass; echo
    read -p "Active days: " days
    expire_date=$(date -d "$days days" +"%Y-%m-%d")
    echo "$user:$pass" >> $USERFILE
    echo "$user $expire_date" >> /etc/Sslablk/udp_users.txt
    read -p "Add IP limit? (y/N): " limit
    if [[ "$limit" =~ ^[Yy]$ ]]; then
        read -p "Source IP (empty=all): " srcip
        read -p "Max UDP packets/sec (default 20): " max_udp
        max_udp=${max_udp:-20}
        read -p "UDP burst (default 40): " udp_burst
        udp_burst=${udp_burst:-40}
        if [[ -n "$srcip" ]]; then
            iptables -I INPUT -p udp -s "$srcip" --dport 7300 -m hashlimit --hashlimit-above "${max_udp}/second" --hashlimit-burst "$udp_burst" --hashlimit-mode srcip --hashlimit-name "udp_${user}" -j DROP
        else
            iptables -I INPUT -p udp --dport 7300 -m hashlimit --hashlimit-above "${max_udp}/second" --hashlimit-burst "$udp_burst" --hashlimit-mode srcip --hashlimit-name "udp_${user}" -j DROP
        fi
        echo "$user|udp-src:$srcip-max:$max_udp-burst:$udp_burst" >> $LIMITFILE
        iptables-save >/etc/iptables.up.rules
    fi
    echo "✅ UDP user created: $user (exp:$expire_date)"
    read -p "ENTER to continue..."
}

create_trojan_ws(){
    clear
    echo "== Create Trojan WebSocket =="
    read -p "Label (username): " user
    read -p "Active days: " days
    uuid=$(cat /proc/sys/kernel/random/uuid)
    expire_date=$(date -d "$days days" +"%Y-%m-%d")
    echo "$user $uuid $expire_date" >> $TROJANFILE
    echo "$user $expire_date" >> /etc/Sslablk/trojan_users_expire.txt
    echo "✅ Trojan WS created: $user (UUID:$uuid, exp:$expire_date)"
    read -p "ENTER to continue..."
}

delete_user(){
    clear
    read -p "Username to delete: " user
    sed -i "/^$user:/d" $USERFILE 2>/dev/null
    sed -i "/^$user /d" $SSHFILE 2>/dev/null
    sed -i "/^$user /d" $TROJANFILE 2>/dev/null
    if id "$user" >/dev/null 2>&1; then userdel -r "$user" 2>/dev/null || true; fi
    sed -i "/^$user|/d" $LIMITFILE
    iptables-save >/etc/iptables.up.rules
    echo "✅ User $user deleted"
    read -p "ENTER to continue..."
}

list_users(){
    clear
    echo "== SSH WS Users =="
    cat $SSHFILE
    echo ""
    echo "== UDP Users =="
    cat $USERFILE
    echo ""
    echo "== Trojan WS Users =="
    cat $TROJANFILE
    read -p "ENTER to continue..."
}

check_udp_active(){
    clear
    echo "== Active UDP Sessions =="
    netstat -anu | grep 7300 || echo "No UDP session active"
    read -p "ENTER to continue..."
}

restart_services(){
    systemctl restart udp-custom
    echo "✅ Services restarted"
    read -p "ENTER to continue..."
}

system_info(){
    clear
    neofetch
    read -p "ENTER to continue..."
}

# ---------- Main Menu ----------
while true; do
    clear
    echo "============================================"
    echo "         SSLABLk VPS Full Menu v2.0"
    echo "============================================"
    echo "1) Create SSH WebSocket"
    echo "2) Create Trojan WebSocket"
    echo "3) Create UDP User"
    echo "4) Delete User"
    echo "5) List Users"
    echo "6) Check Active UDP Sessions"
    echo "7) Restart All Services"
    echo "8) Change Ports (manual config.json)"
    echo "9) VPS Speedtest"
    echo "10) Backup / Restore Users"
    echo "11) System Info"
    echo "12) Exit"
    echo "13) Set IP Limit Manual"
    echo "============================================"
    read -p "Select menu [1-13]: " opt

    case $opt in
        1) create_ssh_ws ;;
        2) create_trojan_ws ;;
        3) create_udp_user ;;
        4) delete_user ;;
        5) list_users ;;
        6) check_udp_active ;;
        7) restart_services ;;
        8) read -p "Edit /root/udp/config.json manually and restart UDP. ENTER to continue..." ;;
        9) speedtest-cli; read -p "ENTER to continue..." ;;
        10) echo "Backup / Restore users not implemented"; read -p "ENTER to continue..." ;;
        11) system_info ;;
        12) exit ;;
        13)
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
        *) echo "Invalid option"; sleep 1 ;;
    esac
done
