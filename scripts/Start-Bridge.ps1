# ====================================================================
# 🌉 Start-Bridge.ps1 – Lancement du BridgeSuite (Node, port 9191)
# ====================================================================
Write-Host "🌉 Démarrage du BridgeSuite (port 9191)..." -ForegroundColor Cyan
Start-Process node -ArgumentList "C:\Ariane-Agent\BridgeSuite\bridge.js" -WindowStyle Hidden
Start-Sleep -Seconds 3
Write-Host "✅ BridgeSuite actif sur le port 9191" -ForegroundColor Green
