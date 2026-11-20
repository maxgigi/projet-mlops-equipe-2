## Ressources machine:
Nous disposons de 4 OptiPlex 7040, de spécifications :
- Processeurs = 4
- Threads par coeurs = 2
- Coeurs par socket = 2 
- Socket = 1
- Ram 16Go pour mem et 16Go pour echange
- Mémoire totale = environ 16 241 000 KB
- Disque sda 465,8 sur 500GB 
- Attention pour machine 64, on a aussi loop0 a 100Gb

## Firmware
Nous avons installé sur nos 4 machines la Debian 13.7 (voir ADR-009).

## Interfaces réseau
Ci dessous les hostnames, n° de machine, adresses MAC et adresses IPs fixes de nos machines : 
- controller - 64 - 64:00:6a:88:64:a9 - 192.168.50.10
- compute1 - 68 - 64:00:6a:85:b3:c9 - 192.168.50.11
- compute2 - 67 - 64:00:6a:85:ae:f1 - 192.168.50.12
- router - 60 - 64:00:6a:88:67:29 - 192.168.50.1

## Câblage
- Pour le router, brancher l'amont (WAN, réseau INSA) sur le port ethernet principal, et brancher le switch (LAN) sur l'adaptateur USB-A vers RJ45 ;
- Brancher le controller et les computes sur le switch, SANS brancher le switch au résseau INSA ;
- Brancher un adaptateur supplémentaire entre le switch et le controller, destiné machines virtuelles du cluster.

## NAT

```
#!/bin/bash
set -e

WAN=enp0s31f6
LAN=enx00e04c680e0d     # à adapter si l'adaptateur change (ip -br link)

# 1. Paquets
apt update && apt install -y nftables dnsmasq

# 2. Forwarding IPv4
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-forward.conf
sysctl --system

# 3. IP fixe sur le LAN (sans gateway)
nmcli con add type ethernet ifname $LAN con-name lan \
  ipv4.method manual ipv4.addresses 192.168.50.1/24
nmcli con up lan

# 4. Firewall + NAT
cat > /etc/nftables.conf <<EOF
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
  chain input {
    type filter hook input priority 0; policy accept;
  }
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    iifname "$LAN" oifname "$WAN" accept
  }
  chain output {
    type filter hook output priority 0; policy accept;
  }
}

table ip nat {
  chain postrouting {
    type nat hook postrouting priority 100; policy accept;
    oifname "$WAN" masquerade
  }
}
EOF

# 5. DHCP + DNS
cat > /etc/dnsmasq.d/lab.conf <<EOF
interface=$LAN
bind-dynamic
domain=lab.local
server=8.8.8.8
server=1.1.1.1
dhcp-range=192.168.50.100,192.168.50.200,12h
dhcp-option=option:router,192.168.50.1
dhcp-option=option:dns-server,192.168.50.1
dhcp-host=64:00:6a:88:64:a9,controller,192.168.50.10
dhcp-host=64:00:6a:85:b3:c9,compute1,192.168.50.11
dhcp-host=64:00:6a:85:ae:f1,compute2,192.168.50.12
EOF

# 6. Activation au boot
systemctl enable --now nftables dnsmasq
systemctl restart nftables dnsmasq
```

