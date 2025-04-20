#!/bin/bash

# WireGuard Full Setup Script for Raspberry Pi (Ubuntu Server)

# COLORS
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Updating system...${NC}"
apt update && apt upgrade -y

echo -e "${GREEN}Installing WireGuard and tools...${NC}"
apt install wireguard qrencode curl ufw -y

# Generate server keys
echo -e "${GREEN}Generating server keys...${NC}"
wg genkey | tee server_private.key | wg pubkey > server_public.key
SERVER_PRIV_KEY=$(cat server_private.key)
SERVER_PUB_KEY=$(cat server_public.key)

# Detect external IP
echo -e "${GREEN}Detecting your public IP...${NC}"
PUB_IP=$(curl -s https://api.ipify.org)

# Ask about DuckDNS
read -p "Do you want to set up DuckDNS? (y/n): " DUCKDNS_CHOICE
if [[ "$DUCKDNS_CHOICE" == "y" ]]; then
    read -p "Enter your DuckDNS subdomain (e.g., myvpn): " DUCKSUB
    read -p "Enter your DuckDNS token: " DUCKTOKEN

    echo -e "${GREEN}Setting up DuckDNS auto-update...${NC}"
    mkdir -p /etc/duckdns
    cat > /etc/duckdns/duck.sh <<EOF
echo url="https://www.duckdns.org/update?domains=$DUCKSUB&token=$DUCKTOKEN&ip=" | curl -k -o /etc/duckdns/duck.log -K -
EOF

    chmod +x /etc/duckdns/duck.sh

    cat > /etc/systemd/system/duckdns.service <<EOF
[Unit]
Description=DuckDNS updater

[Service]
Type=oneshot
ExecStart=/etc/duckdns/duck.sh
EOF

    cat > /etc/systemd/system/duckdns.timer <<EOF
[Unit]
Description=Runs DuckDNS script every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Unit=duckdns.service

[Install]
WantedBy=timers.target
EOF

    systemctl enable --now duckdns.timer
    PUB_IP="$DUCKSUB.duckdns.org"
fi

# Create server config
echo -e "${GREEN}Creating WireGuard server config...${NC}"
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $SERVER_PRIV_KEY
SaveConfig = true
PostUp = ufw route allow in on wg0 out on eth0; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = ufw route delete allow in on wg0 out on eth0; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

# Enable IP forwarding
echo -e "${GREEN}Enabling IP forwarding...${NC}"
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Configure UFW
echo -e "${GREEN}Configuring firewall...${NC}"
ufw allow 51820/udp
sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
sed -i '/^*filter/i *nat\n:POSTROUTING ACCEPT [0:0]\n-A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE\nCOMMIT\n' /etc/ufw/before.rules

ufw --force enable

# Start and enable WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo -e "${GREEN}WireGuard server is running on $PUB_IP:51820${NC}"

# === Add Clients ===
while true; do
    read -p "Do you want to add a VPN client now? (y/n): " ADDCLIENT
    [[ "$ADDCLIENT" != "y" ]] && break

    read -p "Client name (no spaces): " CLIENT_NAME
    CLIENT_PRIV=$(wg genkey)
    CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)

    echo -e "${GREEN}Adding client to server...${NC}"
    wg set wg0 peer $CLIENT_PUB allowed-ips 10.0.0.2/32

    echo -e "${GREEN}Creating client config...${NC}"
    cat > ${CLIENT_NAME}.conf <<EOF
[Interface]
PrivateKey = $CLIENT_PRIV
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUB_KEY
Endpoint = $PUB_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    echo -e "${GREEN}Client config saved as ${CLIENT_NAME}.conf${NC}"
    echo -e "${GREEN}QR Code for mobile devices:${NC}"
    qrencode -t ansiutf8 < ${CLIENT_NAME}.conf
    echo ""
done

echo -e "${GREEN}Setup complete! Use your .conf files to connect from any device.${NC}"