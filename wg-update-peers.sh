#!/bin/bash
set -eux

# add the interface configuration.
cp /etc/wireguard/wg0.conf{.head,}

# add the peers public keys.
for peer_config_path in /vagrant/tmp/wg-peer-*.conf; do
    [ ! -f "$peer_config_path" ] && continue
    cat >>/etc/wireguard/wg0.conf <<EOF

$(cat "$peer_config_path")
EOF
done

# restart wireguard.
systemctl restart wg-quick@wg0

# show info.
wg show

# show listening ports.
ss -n --tcp --listening --processes
ss -n --udp --listening --processes

# show network interfaces.
ip addr

# show network routes.
ip route
