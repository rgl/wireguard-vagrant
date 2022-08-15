$dataPath = "$env:ProgramFiles\WireGuard\Data"
$configurationsPath = "$dataPath\Configurations"
$tunnelName = 'wg0'
$configPath = "$configurationsPath\$tunnelName.conf"
$managerServiceName = 'WireGuardManager'
$tunnelServiceName = "WireGuardTunnel`$$tunnelName"

# stop/uninstall the WireGuardManager service/gui.
# NB we must first stop/uninstall the WireGuardManager service as it tends
#    to crash and burn everything when we update a tunnel from outside of
#    its control.
if (Get-Service -ErrorAction SilentlyContinue $managerServiceName) {
    wireguard /uninstallmanagerservice | Out-String -Stream
    if ($LASTEXITCODE) {
        throw "failed to uninstall the $managerServiceName service with exit code $LASTEXITCODE"
    }
}

# stop/uninstall the tunnel service.
if (Get-Service -ErrorAction SilentlyContinue $tunnelServiceName) {
    wireguard /uninstalltunnelservice $tunnelName | Out-String -Stream
    if ($LASTEXITCODE) {
        throw "failed to uninstall the $tunnelServiceName service with exit code $LASTEXITCODE"
    }
    while (Get-Service -ErrorAction SilentlyContinue $tunnelServiceName) {
        Start-Sleep -Seconds 3
    }
}       

# remove the old tunnel configuration files.
@(
    $configPath
    "$configPath.dpapi"
) | ForEach-Object {
    if (Test-Path $_) {
        Remove-Item $_
    }
}

# create the tunnel configuration file.
# NB when you manually start the wireguard gui application, it will replace
#    the $configPath file with the $configPath.dpapi file as explained in:
#       https://github.com/WireGuard/wireguard-windows/blob/master/docs/enterprise.md
$config = Get-Content -Encoding ascii -Raw "$configPath.head"
Get-ChildItem /vagrant/tmp/wg-peer-*.conf | ForEach-Object {
    $config += "`n"
    $config += Get-Content -Encoding ascii -Raw $_
}
Set-Content -Encoding ascii -NoNewline -Path $configPath -Value $config

# create the tunnel service.
# NB this will create the WireGuardTunnel$wg0 service (which in turn
#    installs/configures the wireguard kernel driver).
# NB when you manually start the wireguard gui application, it will replace
#    this $configPath file with the $configPath.dpapi file as explained in:
#       https://github.com/WireGuard/wireguard-windows/blob/master/docs/enterprise.md
wireguard /installtunnelservice $configPath | Out-String -Stream
if ($LASTEXITCODE) {
    throw "failed to install the $tunnelServiceName service with exit code $LASTEXITCODE"
}
while ($true) {
    $service = Get-Service -ErrorAction SilentlyContinue $tunnelServiceName
    if ($service -and $service.Status -eq 'Running') {
        break
    }
    Start-Sleep -Seconds 3
}

# show info.
wg show $tunnelName

# show network interfaces.
ipconfig

# show network routes.
route print
