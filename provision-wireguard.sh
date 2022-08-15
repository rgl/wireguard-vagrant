#!/bin/bash
set -eux

ip_address="$1"; shift
vpn_ip_address="$1"; shift

# configure the motd.
# NB this was generated at http://patorjk.com/software/taag/#p=display&f=Big&t=WireGuard.
#    it could also be generated with figlet.org.
cat >/etc/motd <<'EOF'

 __          ___           _____                     _
 \ \        / (_)         / ____|                   | |
  \ \  /\  / / _ _ __ ___| |  __ _   _  __ _ _ __ __| |
   \ \/  \/ / | | '__/ _ \ | |_ | | | |/ _` | '__/ _` |
    \  /\  /  | | | |  __/ |__| | |_| | (_| | | | (_| |
     \/  \/   |_|_|  \___|\_____|\__,_|\__,_|_|  \__,_|


EOF

# install wireguard.
# see https://www.wireguard.com/install/
apt-get install -y wireguard

# create the configuration file.
# see https://git.zx2c4.com/wireguard-tools/about/src/man/wg-quick.8
umask 077
wg genkey >"$(hostname).key"
cat >/etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $(cat "$(hostname).key")
Address = $vpn_ip_address/24
ListenPort = 51820
EOF
cp /etc/wireguard/wg0.conf{,.head}
umask 022

# save this peer configuration in the host.
mkdir -p /vagrant/tmp
cat >"/vagrant/tmp/wg-peer-$(hostname).conf" <<EOF
[Peer]
PublicKey = $(wg pubkey <"$(hostname).key")
Endpoint = $ip_address:51820
AllowedIPs = $vpn_ip_address/32
EOF

# delete the keypair.
rm "$(hostname).key"

# bring up the interface.
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# show info.
wg show
