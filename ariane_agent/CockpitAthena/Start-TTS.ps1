# ====================================================================
# 🗣️ Start-TTS.ps1 – Lancement du serveur vocal (Flask, port 5070)
# ====================================================================
Write-Host "🗣️ Lancement du module vocal TTS sur le port 5070..." -ForegroundColor Cyan
Start-Process python -ArgumentList "C:\Ariane-Agent\CockpitAthena\tts_server.py" -WindowStyle Hidden
Start-Sleep -Seconds 3
Write-Host "✅ Serveur vocal prêt sur http://localhost:5070" -ForegroundColor Green
