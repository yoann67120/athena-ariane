# Start-Monitor.ps1
$script = "C:/Ariane-Agent/Scripts/Monitor-Athena.ps1"
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$script`"" -WindowStyle Hidden
Write-Host "✅ Monitor démarré."