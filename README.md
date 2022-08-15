# WireGuard

Install the base [ubuntu 20.04 vagrant box](https://github.com/rgl/ubuntu-vagrant).

Launch the environment:

```bash
time vagrant up --provider=libvirt # or --provider=virtualbox
```

After the environment is up, each machine wireguard configuration will have
all the other machines as peers, e.g., `/etc/wireguard/wg0.conf` will be:

```plain
[Interface]
PrivateKey = +Ps5ijDqZxUtJgXvojG1fMsO6wL3SJixj9s5Glaud3U=
Address = 10.2.0.100/24
ListenPort = 51820

[Peer]
PublicKey = vv0x1c4a93XT0MYhHDHGsxJ2ZZq3uxHugKqj+pa83i0=
Endpoint = 192.168.53.100:51820
AllowedIPs = 10.2.0.100/32

[Peer]
PublicKey = 7S2H6RphXcDLyalL1T/b5Pxmr53137ZmccVRGdgPQDw=
Endpoint = 192.168.53.101:51820
AllowedIPs = 10.2.0.101/32
```

## References

* https://www.wireguard.com/
* [wg-quick(8)](https://git.zx2c4.com/wireguard-tools/about/src/man/wg-quick.8)
* https://wiki.archlinux.org/index.php/WireGuard
* https://wiki.debian.org/Wireguard
