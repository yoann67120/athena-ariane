# ====================================================================
# 🔐 Invoke-UsineSecureRequest.ps1 (v2 - Correctif HMAC)
# Génère la signature HMAC-SHA256 correcte et envoie la requête sécurisée
# ====================================================================

param(
    [string]$Url = "https://4a22bf9c7fca.ngrok-free.app/bridge",
    [string]$Action = "list_projects",
    [hashtable]$Params = @{}
)

$Secret = "ARIANE_SECRET_2025"
$Token  = "ARIANE_LOCAL_KEY"

# Construction du JSON
$BodyObject = @{
    protocol = "UsineProtocol_v1"
    source   = "GPT5"
    token    = $Token
    action   = $Action
    params   = $Params
    context  = @{ mode = "secure" }
}
$BodyJson = ($BodyObject | ConvertTo-Json -Depth 5)

# --- ✅ Correction ici ---
$KeyBytes  = [System.Text.Encoding]::UTF8.GetBytes($Secret)
$BodyBytes = [System.Text.Encoding]::UTF8.GetBytes($BodyJson)
$HMAC      = [System.Security.Cryptography.HMACSHA256]::new($KeyBytes)
$Signature = ($HMAC.ComputeHash($BodyBytes) | ForEach-Object { $_.ToString("x2") }) -join ""
# --------------------------

# Envoi de la requête sécurisée
Write-Host "🔐 Signature générée : $Signature" -ForegroundColor Cyan
Write-Host "🌍 Envoi vers $Url (action=$Action)" -ForegroundColor Green

$response = Invoke-RestMethod -Uri $Url `
  -Method POST `
  -ContentType "application/json" `
  -Headers @{ "X-Signature" = $Signature } `
  -Body $BodyJson

$response | ConvertTo-Json -Depth 5
