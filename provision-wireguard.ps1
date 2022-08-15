param(
    $ipAddress='192.168.53.101',
    $vpnIpAddress='10.2.0.101'
)

# see https://community.chocolatey.org/packages/wireguard
$version = '0.5.3'

# install.
# see https://www.wireguard.com/install/
choco install -y wireguard --version $version

# load Carbon.
Import-Module Carbon

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"
Update-SessionEnvironment

# create the configuration file.
# see https://git.zx2c4.com/wireguard-windows/tree/
$nodeName = $env:COMPUTERNAME.ToLowerInvariant()
$etcPath = 'C:\ProgramData\WireGuard'
$configPath = "$etcPath\wg0.conf"
if (Test-Path $etcPath) {
    Remove-Item -Recurse -Force $etcPath
}
mkdir $etcPath | Out-Null
Disable-CAclInheritance $etcPath
Grant-CPermission $etcPath Administrators FullControl
Grant-CPermission $etcPath $env:USERNAME FullControl
$keyPath = "$etcPath\$nodeName.key"
$key = wg genkey
Set-Content -Encoding ascii -NoNewline -Path $keyPath -Value $key
Set-Content -Encoding ascii -NoNewline -Path $configPath -Value @"
[Interface]
PrivateKey = $key
Address = $vpnIpAddress/24
ListenPort = 51820

"@
Copy-Item $configPath "$configPath.head"

# save this peer configuration in the host.
if (!(Test-Path c:/vagrant/tmp)) {
    mkdir -p /vagrant/tmp | Out-Null
}
Set-Content -Encoding ascii -NoNewline -Path "/vagrant/tmp/wg-peer-$nodeName.conf" -Value @"
[Peer]
PublicKey = $($key | wg pubkey)
Endpoint = ${ipAddress}:51820
AllowedIPs = $vpnIpAddress/32

"@

# delete the keypair.
Remove-Item $keyPath

# apply the configuration.
# NB this will create the WireGuardTunnel$wg0 service (which in turn
#    installs/configures the wireguard kernel driver).
wireguard /installtunnelservice $configPath | Out-String -Stream
if ($LASTEXITCODE) {
    throw "failed to install the WireGuardTunnel`$wg0 service with exit code $LASTEXITCODE"
}

# allow inbound WireGuard traffic.
New-NetFirewallRule `
    -Name 'WireGuard-UDP' `
    -DisplayName 'WireGuard (UDP-In)' `
    -Direction Inbound `
    -Enabled True `
    -Protocol UDP `
    -LocalPort 51820 `
    | Out-Null

# show info.
wg show
