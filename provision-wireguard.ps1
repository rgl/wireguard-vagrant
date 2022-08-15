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
$dataPath = "$env:ProgramFiles\WireGuard\Data"
$configurationsPath = "$dataPath\Configurations"
$configPath = "$configurationsPath\wg0.conf"
if (Test-Path $dataPath) {
    Remove-Item -Recurse -Force $dataPath
}
mkdir $dataPath | Out-Null
Disable-CAclInheritance $dataPath
Grant-CPermission $dataPath SYSTEM FullControl
Grant-CPermission $dataPath Administrators FullControl
mkdir $configurationsPath | Out-Null
$key = wg genkey
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

# apply the configuration.
# NB this will create the WireGuardTunnel$wg0 service (which in turn
#    installs/configures the wireguard kernel driver).
# NB when you manually start the wireguard gui application, it will replace
#    this $configPath file with the $configPath.dpapi file as explained in:
#       https://github.com/WireGuard/wireguard-windows/blob/master/docs/enterprise.md
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
