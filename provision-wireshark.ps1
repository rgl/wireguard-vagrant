choco install -y wireshark

Set-Content "$env:USERPROFILE\ConfigureDesktop-WireShark.ps1" @'
Install-ChocolateyShortcut `
    -ShortcutFilePath "$env:USERPROFILE\Desktop\Wireshark.lnk" `
    -TargetPath 'C:\Program Files\Wireshark\Wireshark.exe'
'@

# leave npcap on the desktop for the user to install manually.
# (it does not have a silent installer).
# see https://github.com/nmap/npcap/releases
# see https://npcap.com/#download
$url = 'https://npcap.com/dist/npcap-1.70.exe'
$expectedHash = '53913ee65ac54927c793254d7404d40c57432de18b60feb3bd9cfd554d38dde9'
$localPath = "$env:USERPROFILE\Desktop\$(Split-Path -Leaf $url)"
(New-Object Net.WebClient).DownloadFile($url, $localPath)
$actualHash = (Get-FileHash $localPath -Algorithm SHA256).Hash
if ($actualHash -ne $expectedHash) {
    throw "downloaded file from $url to $localPath has $actualHash hash that does not match the expected $expectedHash"
}
