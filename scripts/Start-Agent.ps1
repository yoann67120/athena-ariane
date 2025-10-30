# ====================================================================
# 🚀 Start-Agent.ps1 – Lancement du serveur Agent (Flask, port 5000)
# ====================================================================
Write-Host "⚙️ Lancement du serveur Agent Flask sur le port 5000..." -ForegroundColor Cyan
Start-Process python -ArgumentList "C:\Ariane-Agent\agent.py" -WindowStyle Hidden
Start-Sleep -Seconds 3
Write-Host "✅ Agent Flask lancé sur http://localhost:5000" -ForegroundColor Green
