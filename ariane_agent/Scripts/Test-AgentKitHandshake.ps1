# ====================================================================
# 🚀 ARIANE V4 - TEST HANDSHAKE AGENTKIT CLOUD
# Auteur : Yoann Rousselle
# Description : Vérifie la connexion Cloud ↔ Bridge local (Phase 25)
# ====================================================================

$ErrorActionPreference = "SilentlyContinue"
$BaseDir   = "C:\Ariane-Agent"
$LogDir    = "$BaseDir\logs"
$SecretKey = "$BaseDir\secrets\bridge_hmac.key"
$LogFile   = "$LogDir\AgentKitCloud.log"
$NgrokPath = "$BaseDir\Tools\ngrok.exe"
$BridgeURL = "https://ariane.ngrok.io/bridge/handshake"

# --- Préparation des logs ---
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] === DÉMARRAGE TEST HANDSHAKE ===" | Out-File -FilePath $LogFile -Append

# --- Vérification du tunnel ---
$tunnels = (Get-Process ngrok -ErrorAction SilentlyContinue)
if (-not $tunnels) {
    Write-Host "🌐 Tunnel ngrok inactif — lancement automatique..." -ForegroundColor Yellow
    Start-Process -FilePath $NgrokPath -ArgumentList "http 5075" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

# --- Lecture de la clé HMAC ---
if (!(Test-Path $SecretKey)) {
    Write-Host "❌ Clé HMAC introuvable à $SecretKey" -ForegroundColor Red
    exit
}
$key = Get-Content $SecretKey -Raw

# --- Envoi du handshake ---
Write-Host "🤝 Envoi du handshake vers $BridgeURL..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri $BridgeURL -Method Post -Headers @{"Content-Type"="application/json"} -TimeoutSec 10
    $json = $response | ConvertTo-Json -Depth 5
    Write-Host "✅ Réponse du Bridge :" -ForegroundColor Green
    Write-Host $json
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $json" | Out-File -FilePath $LogFile -Append
}
catch {
    Write-Host "❌ Échec du handshake : $($_.Exception.Message)" -ForegroundColor Red
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append
}

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] === FIN TEST HANDSHAKE ===`n" | Out-File -FilePath $LogFile -Append
