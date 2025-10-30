# ====================================================================
# 🚀 ARIANE V4 – PHASE 16 : ENREGISTREMENT AGENTKIT CLOUD
# Auteur : Yoann Rousselle
# ====================================================================

param (
    [string]$AgentKitCloudURL = "https://ariane.ngrok.io/bridge/register",
    [string]$BridgeURL        = "https://ariane.ngrok.io/bridge",
    [string]$SecretPath       = "C:\Ariane-Agent\secrets\bridge_hmac.key",
    [string]$LogFile          = "C:\Ariane-Agent\logs\AgentCloud.log"
)

# --- Vérifications ---
if (!(Test-Path $SecretPath)) {
    Write-Host "❌ Clé HMAC introuvable : $SecretPath" -ForegroundColor Red
    exit 1
}
if (!(Test-Path (Split-Path $LogFile))) {
    New-Item -ItemType Directory -Force -Path (Split-Path $LogFile) | Out-Null
}

# --- Chargement clé ---
$SecretKey = (Get-Content $SecretPath -Raw).Trim()

# --- Métadonnées correctes ---
$Payload = @{
    bridge_url = $BridgeURL
    timestamp  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    hmac_key   = $SecretKey
    system     = "ArianeV4"
}

$JsonBody = $Payload | ConvertTo-Json -Depth 4

function Write-Log {
    param([string]$Message)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$ts] $Message"
    Write-Host "[$ts] $Message"
}

# --- Étape 1 : Enregistrement du Bridge ---
Write-Host "🌍 Envoi de l'enregistrement du Bridge à AgentKit Cloud..." -ForegroundColor Cyan
try {
    $resp = Invoke-RestMethod -Uri $AgentKitCloudURL -Method POST -Body $JsonBody -ContentType "application/json"
    Write-Log "✅ Bridge ArianeV4 enregistré dans AgentKit Cloud."
    Write-Log "↩️ Réponse Cloud : $($resp | ConvertTo-Json -Depth 4)"
}
catch {
    Write-Log "❌ Erreur d'enregistrement : $($_.Exception.Message)"
    exit 1
}

# --- Étape 2 : Test Cloud → Bridge → Usine ---
Write-Host "🔁 Test de la commande list_projects via Bridge..." -ForegroundColor Yellow
$TestBody = @{ action = "list_projects"; source = "AgentKitCloud" } | ConvertTo-Json
try {
    $res = Invoke-RestMethod -Uri $BridgeURL -Method POST -Body $TestBody -ContentType "application/json"
    Write-Log "✅ Test réussi : Cloud ↔ Bridge ↔ Usine opérationnel."
    Write-Log "🔎 Résultat : $($res | ConvertTo-Json -Depth 4)"
}
catch {
    Write-Log "❌ Erreur durant le test list_projects : $($_.Exception.Message)"
}

Write-Host "`n===============================================" -ForegroundColor Green
Write-Host "✅ Enregistrement terminé. Log : $LogFile" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
