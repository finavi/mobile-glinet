#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# === Root privileges check ===
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] You must run this script as root!${NC}"
    exit 1
fi

echo -e "${YELLOW}[+] Starting network configuration for Burp interception...${NC}"

# === Check for ethtool ===
if ! command -v ethtool &> /dev/null; then
    echo -e "${RED}[!] 'ethtool' is not installed. Install it with: sudo apt install ethtool.${NC}"
    exit 1
fi

# === Check physical connection on eth1 ===
echo -e "${YELLOW}[+] Checking link status on eth1...${NC}"
if ethtool eth1 | grep -q "Link detected: no"; then
    echo -e "${RED}[!] No active link on eth1. Check the router connection and try again.${NC}"
    exit 1
else
    echo -e "${GREEN}[+] Link detected on eth1.${NC}"
fi

# === Get VPN IP (tun0) ===
ipVpn=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -z "$ipVpn" ]; then
    echo -e "${RED}[!] No active VPN connection found on tun0. Exiting...${NC}"
    exit 1
fi

# === Get Burp IP (eth0) ===
ipBurp=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -z "$ipBurp" ]; then
    echo -e "${RED}[!] No active connection found on eth0. Exiting...${NC}"
    exit 1
fi

echo -e "${GREEN}[+] VPN IP detected: $ipVpn${NC}"

# === Get or assign IP to eth1 (GL.iNet router subnet) ===
ipGlinet=$(ip -4 addr show eth1 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -z "$ipGlinet" ]; then
    echo -e "${YELLOW}[+] No IP found on eth1. Assigning 192.168.10.1...${NC}"
    ip addr add 192.168.10.1/24 dev eth1
    ipGlinet="192.168.10.1"
else
    echo -e "${GREEN}[+] eth1 is already configured with IP: $ipGlinet${NC}"
fi

# === Bring eth1 up ===
echo -e "${YELLOW}[+] Bringing up interface eth1...${NC}"
ip link set dev eth1 up

# === Enable IP forwarding ===
echo -e "${YELLOW}[+] Enabling IP forwarding...${NC}"
echo 1 > /proc/sys/net/ipv4/ip_forward

# === IPTABLES: allow traffic from victim ===
echo -e "${YELLOW}[+] Adding iptables FORWARD rules for victim traffic...${NC}"
iptables -I FORWARD -s 192.168.10.200 -j ACCEPT
iptables -I FORWARD -d 192.168.10.200 -j ACCEPT

# === SNAT: rewrite source IP for outbound traffic ===
echo -e "${YELLOW}[+] Adding SNAT rule (source NAT)...${NC}"
iptables -t nat -I POSTROUTING -s 192.168.10.200 -j SNAT --to $ipVpn

# === Redirect HTTP/HTTPS to Burp ===
echo -e "${YELLOW}[+] Redirecting HTTP/HTTPS traffic to Burp (${ipBurp}:8080)...${NC}"
iptables -t nat -I PREROUTING -s 192.168.10.200 -p tcp --dport 80 -j DNAT --to $ipBurp:8080
iptables -t nat -I PREROUTING -s 192.168.10.200 -p tcp --dport 443 -j DNAT --to $ipBurp:8080

echo -e "${GREEN}[+] Configuration completed!${NC}"
echo -e "${YELLOW}[!] Make sure Burp is running in invisible proxy mode on ${ipBurp}:8080${NC}"
