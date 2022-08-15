$etcPath = 'C:\ProgramData\WireGuard'
$configPath = "$etcPath\wg0.conf"
$serviceName = 'WireGuardTunnel$wg0'

# update the configuration file.
$config = Get-Content -Encoding ascii -Raw "$configPath.head"
Get-ChildItem /vagrant/tmp/wg-peer-*.conf | ForEach-Object {
    $config += "`n"
    $config += Get-Content -Encoding ascii -Raw $_
}
Set-Content -Encoding ascii -NoNewline -Path $configPath -Value $config

# restart wireguard.
Restart-Service $serviceName

# show info.
wg show

# show network interfaces.
ipconfig

# show network routes.
route print
