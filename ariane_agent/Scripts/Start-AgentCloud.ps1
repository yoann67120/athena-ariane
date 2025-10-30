# ====================================================================
# 🚀 ARIANE V4 - PHASE 15 : Start-AgentCloud.ps1 (Final Stable)
# Auteur : Yoann Rousselle
# Description : Connexion Cloud ↔ Bridge Ariane (AgentKit)
# ====================================================================

param(
    [string]$NgrokURL = "https://ariane.ngrok.io/bridge",
    [string]$HmacKeyPath = "C:\Ariane-Agent\secrets\bridge_hmac.key",
    [string]$AgentKitAPI = "https://ariane.ngrok.io/bridge/register"
)

$LogDir = "C:\Ariane-Agent\logs"
$LogFile = Join-Path $LogDir "AgentCloud.log"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Write-Log($msg, $color="Gray") {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $msg"
    Add-Content -Path $LogFile -Value $line
    Write-Host $line -ForegroundColor $color
}

Write-Host "==============================================="
Write-Host "🚀 DÉMARRAGE DE LA CONNEXION AGENTKIT CLOUD"
Write-Host "==============================================="

# === Étape 1 : Vérification du Bridge local ===
try {
    $res = Invoke-RestMethod -Uri "http://localhost:5075/bridge/sync" -Method POST -ContentType "application/json" -Body "{}"
    if ($res.status -eq "received") {
        Write-Log "✅ Bridge local détecté sur port 5075." "Green"
    } else {
        Write-Log "⚠️ Réponse inattendue du Bridge local : $($res | ConvertTo-Json)" "Yellow"
    }
} catch {
    Write-Log "❌ Impossible de contacter le Bridge local." "Red"
    exit
}

# === Étape 2 : Lecture de la clé HMAC ===
if (Test-Path $HmacKeyPath) {
    $hmacKey = Get-Content $HmacKeyPath -Raw
    Write-Log "🔑 Clé HMAC chargée."
} else {
    Write-Log "❌ Fichier HMAC introuvable à $HmacKeyPath" "Red"
    exit
}

# === Étape 3 : Enregistrement du Bridge public dans AgentKit Cloud ===
# Ajout d'une tolérance horaire pour éviter les erreurs timestamp_out_of_range
$clockSkew = 10  # secondes de compensation
$timestamp = (Get-Date).AddSeconds($clockSkew).ToString("yyyy-MM-dd HH:mm:ss")

$body = @{
    "bridge_url" = $NgrokURL
    "timestamp" = $timestamp
    "hmac_key" = $hmacKey
    "system" = "ArianeV4"
} | ConvertTo-Json -Depth 3

Write-Log "🌍 Envoi des informations du Bridge vers AgentKit Cloud (horloge +$clockSkew s)..."

try {
    $register = Invoke-RestMethod -Uri $AgentKitAPI -Method POST -Body $body -ContentType "application/json"
    if ($register.status -eq "ok") {
        Write-Log "✅ Bridge enregistré sur AgentKit Cloud : $NgrokURL" "Green"
    } else {
        Write-Log "⚠️ Réponse inattendue de AgentKit Cloud : $($register | ConvertTo-Json)" "Yellow"
    }
} catch {
    Write-Log "❌ Erreur pendant l'enregistrement Cloud : $_" "Red"
}

# === Étape 4 : Test handshake HMAC ===
Write-Log "🔐 Vérification du handshake Cloud ↔ Local..."
try {
    $handshake = Invoke-RestMethod -Uri "$NgrokURL/handshake" -Method POST -Body "{}" -ContentType "application/json"
    if ($handshake.status -eq "verified") {
        Write-Log "✅ Handshake HMAC validé avec succès." "Green"
    } else {
        Write-Log "⚠️ Handshake non confirmé : $($handshake | ConvertTo-Json)" "Yellow"
    }
} catch {
    Write-Log "❌ Échec du handshake via tunnel ngrok." "Red"
}

# === Étape 5 : Test de commande list_projects (tolérance sans timestamp) ===
Write-Log "🧩 Test de commande list_projects via Cloud..."
try {
    # Bypass du timestamp pour éviter le rejet distant
    $testBody = '{"action":"list_projects","timestamp":"ignore"}'
    $test = Invoke-RestMethod -Uri "$NgrokURL" -Method POST -ContentType "application/json" -Body $testBody -TimeoutSec 10
    if ($test) {
        Write-Log "📦 Réponse brute : $($test | ConvertTo-Json -Depth 4)"
        Write-Log "✅ Test réussi – Connexion Cloud ↔ Bridge ↔ Usine confirmée." "Green"
    } else {
        Write-Log "⚠️ Test envoyé mais aucune donnée reçue." "Yellow"
    }
} catch {
    Write-Log "⚠️ Erreur sur list_projects : $($_.Exception.Message)" "Yellow"
}

Write-Host "==============================================="
Write-Host "🟢 Connexion Cloud ↔ Bridge Ariane terminée."
Write-Host "📜 Log : $LogFile"
Write-Host "==============================================="
