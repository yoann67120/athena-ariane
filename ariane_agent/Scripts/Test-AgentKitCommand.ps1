# ====================================================================
# 🚀 ARIANE V4 – TEST AGENTKIT CLOUD (Signature HMAC alignée SelfGuard)
# ====================================================================

$ErrorActionPreference = "Stop"
$BaseDir   = "C:\Ariane-Agent"
$SecretKey = "$BaseDir\secrets\bridge_hmac.key"
$BridgeURL = "https://ariane.ngrok.io/bridge"
$Action    = "create_project"
$Payload   = @{ name = "Cloud_Test_03" }

# --- Lecture de la clé (binaire) ---
$key = [System.IO.File]::ReadAllBytes($SecretKey)

# --- Métadonnées ---
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$nonce = [System.Guid]::NewGuid().ToString("N")

# --- Sérialisation du payload (tri + compact) ---
$jsonPayload = ($Payload | ConvertTo-Json -Compress)
# ConvertTo-Json ne trie pas ; on peut ignorer l’ordre des clés pour ce test simple.

# --- Construction du message EXACT attendu par SelfGuard ---
$message = "$Action|$timestamp|$nonce|$jsonPayload"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($message)

# --- Calcul HMAC SHA256 ---
$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
$hmacsha.Key = $key
$signatureBytes = $hmacsha.ComputeHash($bytes)
$signature = ([System.BitConverter]::ToString($signatureBytes)).Replace("-", "").ToLower()

Write-Host "🔐 Message signé :" $message
Write-Host "🔑 Signature générée :" $signature -ForegroundColor Cyan

# --- Corps de requête (seulement action/payload) ---
$body = @{
    action  = $Action
    payload = $Payload
} | ConvertTo-Json -Compress

# --- Envoi ---
$response = Invoke-RestMethod -Uri $BridgeURL -Method Post `
    -Headers @{
        "Content-Type" = "application/json"
        "X-HMAC"       = $signature
        "X-Timestamp"  = $timestamp
        "X-Nonce"      = $nonce
    } `
    -Body $body

Write-Host "`n✅ Réponse du Bridge :"
$response | ConvertTo-Json -Depth 5
