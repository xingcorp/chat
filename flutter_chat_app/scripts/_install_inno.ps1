# Temporary script to download and install Inno Setup 6
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$installerUrl = 'https://jrsoftware.org/download.php/is.exe'
$installerPath = Join-Path $env:TEMP 'innosetup_installer.exe'

Write-Host 'Downloading Inno Setup 6...' -ForegroundColor Cyan
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
Write-Host "Downloaded: $installerPath" -ForegroundColor Green

$fileSize = [math]::Round((Get-Item $installerPath).Length / 1MB, 1)
Write-Host "File size: ${fileSize} MB" -ForegroundColor Cyan

Write-Host 'Installing Inno Setup 6 (silent)...' -ForegroundColor Cyan
Start-Process -FilePath $installerPath -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait

# Verify installation
$isccPath = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
if (Test-Path $isccPath) {
    Write-Host "Inno Setup 6 installed successfully at: $isccPath" -ForegroundColor Green
} else {
    Write-Host 'Installation may have failed. Check manually.' -ForegroundColor Red
}

# Cleanup
Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
