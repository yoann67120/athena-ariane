# ====================================================================
# 🚀 Start-Usine.ps1
# Démarrage automatique de l’Usine à Projets (Flask + AgentKit)
# ====================================================================

$ErrorActionPreference = "SilentlyContinue"
$logPath = "C:\Ariane-Agent\logs\Start-Usine.log"
$usinePath = "C:\Ariane-Agent\UsineAProjets\usine_server.py"

# --- Vérification AgentKit ---
if (!(Test-Path "C:\Ariane-Agent\agentkit\__init__.py")) {
    Write-Host "❌ AgentKit introuvable. Vérifie ton installation." -ForegroundColor Red
    exit
}

# --- Écriture log de lancement ---
$ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
"[$ts] 🚀 Démarrage de l’Usine à Projets..." | Out-File -FilePath $logPath -Encoding UTF8 -Append

# --- Démarrage du serveur Flask ---
Write-Host "⚙️ Lancement du serveur Flask sur le port 5050..." -ForegroundColor Yellow
Start-Process -NoNewWindow -FilePath "python" -ArgumentList $usinePath

# --- Attente courte ---
Start-Sleep -Seconds 3

# --- Ouverture navigateur ---
Start-Process "http://localhost:5050"

Write-Host "✅ Usine à Projets lancée et accessible sur http://localhost:5050" -ForegroundColor Green
"[$ts] ✅ Serveur lancé avec succès." | Out-File -FilePath $logPath -Encoding UTF8 -Append
