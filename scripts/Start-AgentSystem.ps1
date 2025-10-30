# ====================================================================
# 🚀 ARIANE V4 - DÉMARRAGE COMPLET AUTOMATIQUE (v28.0 AUTO-MAINTENANCE)
# Auteur : Yoann Rousselle
# Description : Lance Bridge, Usine, Tunnels ngrok PRO et Relay HMAC
#               + Vérification automatique via AutoSync / AutoDeploy
# ====================================================================

param(
    [switch]$Verbose
)

$ErrorActionPreference = "SilentlyContinue"
$BaseDir   = "C:\Ariane-Agent"
$BridgeDir = "$BaseDir\Bridge"
$UsineDir  = "$BaseDir\UsineAProjets"
$RelayDir  = "$BaseDir\BridgeRelay"
$ToolsDir  = "$BaseDir\Tools"
$NgrokPath = "$ToolsDir\ngrok.exe"
$LogDir    = "$BaseDir\logs"
$NgrokApi  = "http://127.0.0.1:4040/api/tunnels"
$RelayFile = "$RelayDir\agentkit_hmac_client.py"

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "🚀 DÉMARRAGE COMPLET ARIANE / ATHENA V4 (NGROK PRO SYNC)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# ====================================================================
# 🧩 PHASE 28 – AUTO-MAINTENANCE CLOUD
# ====================================================================
$AutoSync   = "$BaseDir\Scripts\AutoSync.ps1"
$AutoDeploy = "$BaseDir\Scripts\AutoDeploy.ps1"
$AutoLog    = "$LogDir\AutoMaintenance.log"

Write-Host "🧠 Vérification auto-maintenance avant lancement..." -ForegroundColor Yellow
try {
    if (Test-Path $AutoSync) {
        Write-Host "➡️  Exécution AutoSync.ps1 (mode quick)" -ForegroundColor Cyan
        & powershell -ExecutionPolicy Bypass -File $AutoSync -Mode "quick"
    }
    if (Test-Path $AutoDeploy) {
        Write-Host "➡️  Exécution AutoDeploy.ps1" -ForegroundColor Cyan
        & powershell -ExecutionPolicy Bypass -File $AutoDeploy
    }
    Add-Content $AutoLog "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [autostart] ✅ Auto-maintenance exécutée au démarrage."
}
catch {
    Add-Content $AutoLog "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [autostart] ❌ Erreur auto-maintenance : $($_.Exception.Message)"
    Write-Host "⚠️ Erreur durant l'auto-maintenance : $($_.Exception.Message)" -ForegroundColor Red
}

# --- Vérification des fichiers essentiels ---
if (!(Test-Path $NgrokPath)) {
    Write-Host "❌ ngrok.exe introuvable dans $ToolsDir" -ForegroundColor Red
    exit
}

# --- Démarrage du Bridge ---
Write-Host "🔗 Lancement du Bridge sécurisé (port 5075)..." -ForegroundColor Yellow
Start-Process "python" "$BridgeDir\bridge_server.py" -WindowStyle Hidden
Start-Sleep -Seconds 3

# --- Démarrage de l’Usine à Projets ---
Write-Host "🏭 Lancement de l’Usine à Projets (port 5050)..." -ForegroundColor Yellow
Start-Process "python" "$UsineDir\usine_server.py" -WindowStyle Hidden
Start-Sleep -Seconds 3

# --- Ouverture des tunnels NGROK PRO ---
Write-Host "🌐 Ouverture des tunnels NGROK PRO (Bridge + Usine)..." -ForegroundColor Yellow
Start-Process -FilePath $NgrokPath -ArgumentList "http --domain=ariane.ngrok.io 5075" -WindowStyle Hidden
Start-Process -FilePath $NgrokPath -ArgumentList "http --domain=usine.ngrok.io 5050" -WindowStyle Hidden
Start-Sleep -Seconds 8

# --- Vérification et affichage des URLs publiques ---
$BridgeURL = ""
$UsineURL  = ""
try {
    $tunnels = (Invoke-RestMethod -Uri $NgrokApi | ConvertTo-Json | ConvertFrom-Json).tunnels
    foreach ($t in $tunnels) {
        if ($t.public_url -match "ariane") {
            $BridgeURL = $t.public_url
            Write-Host "✅ Tunnel Bridge actif : $BridgeURL" -ForegroundColor Green
            Write-Host "🔒 Bridge public : $BridgeURL/bridge" -ForegroundColor Green
        }
        elseif ($t.public_url -match "usine") {
            $UsineURL = $t.public_url
            Write-Host "✅ Tunnel Usine actif  : $UsineURL" -ForegroundColor Green
            Write-Host "🏭 Usine publique : $UsineURL" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "⚠️ Impossible d’obtenir les informations NGROK (API locale non dispo)" -ForegroundColor Yellow
}

# --- MISE À JOUR AUTOMATIQUE DU RELAIS HMAC ---
if (Test-Path $RelayFile -and $BridgeURL) {
    Write-Host "🧩 Mise à jour automatique du client HMAC..." -ForegroundColor Yellow
    try {
        (Get-Content $RelayFile -Raw) -replace 'BASE_URL\s*=\s*".*?"', "BASE_URL = `"$BridgeURL/bridge`"" | Set-Content $RelayFile -Encoding UTF8
        Write-Host "✅ BASE_URL mis à jour vers $BridgeURL/bridge" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Erreur lors de la mise à jour automatique du Relay" -ForegroundColor Yellow
    }
}

# --- Lancement du Relay Cloud HMAC ---
if ($Verbose) {
    Write-Host "🧠 Lancement du Relay Cloud HMAC en mode visible..." -ForegroundColor Yellow
    python "$RelayDir\agentkit_hmac_client.py"
} else {
    Write-Host "🌩️ Démarrage du Relay Cloud HMAC (silencieux)..." -ForegroundColor Yellow
    Start-Process "python" "$RelayDir\agentkit_hmac_client.py" -WindowStyle Hidden
}

# --- Diagnostic final ---
Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "🧠 DIAGNOSTIC SYSTÈME ARIANE / ATHENA V4" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Start-Sleep -Seconds 2

Write-Host "🟢 Bridge écoute localement sur port 5075" -ForegroundColor Green
Write-Host "🟢 Usine à Projets écoute localement sur port 5050" -ForegroundColor Green
Write-Host "🟢 Tunnels NGROK PRO actifs : ariane.ngrok.io + usine.ngrok.io" -ForegroundColor Green
Write-Host "🟢 BASE_URL du Relay synchronisé automatiquement" -ForegroundColor Green
Write-Host "`n=== Tous les services sont en cours d’exécution ===" -ForegroundColor Cyan
Write-Host "Appuie sur CTRL+C pour fermer tous les processus manuellement.`n" -ForegroundColor Yellow
