# ====================================================================
# 🚀 ARIANE V4 - INVOKE AGENT CLOUD COMMAND (Phase 17 corrigée)
# Auteur : Yoann Rousselle
# Objectif : Générer une signature HMAC compatible SelfGuard.py
# ====================================================================

param (
    [Parameter(Mandatory = $true)]
    [string]$Action
)

# === Configuration ===
$BaseDir = "C:\Ariane-Agent"
$SecretPath = "$BaseDir\secrets\bridge_hmac.key"
$LogFile = "$BaseDir\logs\AgentCloudCommand.log"
$BridgeURL = "https://ariane.ngrok.io/bridge"

# === Chargement de la clé HMAC ===
if (!(Test-Path $SecretPath)) {
    Write-Host "❌ Clé HMAC introuvable : $SecretPath" -ForegroundColor Red
    exit
}
$SecretBytes = [System.IO.File]::ReadAllBytes($SecretPath)

# === Préparation du payload ===
$Timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$Nonce = [guid]::NewGuid().ToString("N")
$Payload = @{ source = "AgentCloud"; request = "list_projects" }

# Construction du message EXACT attendu par SelfGuard.py
# Format : action|timestamp|nonce|{payload JSON trié sans espaces}
$PayloadJson = ($Payload | ConvertTo-Json -Compress | ForEach-Object {$_ -replace '\s',''})
$Message = "$Action|$Timestamp|$Nonce|$PayloadJson"
$MessageBytes = [System.Text.Encoding]::UTF8.GetBytes($Message)

# Calcul HMAC SHA256
$Hmac = New-Object System.Security.Cryptography.HMACSHA256
$Hmac.Key = $SecretBytes
$Hash = $Hmac.ComputeHash($MessageBytes)
$Signature = -join ($Hash | ForEach-Object { "{0:x2}" -f $_ })

# === Envoi HTTP sécurisé ===
$Headers = @{
    "Content-Type" = "application/json"
    "X-HMAC"       = $Signature
    "X-Nonce"      = $Nonce
    "X-Timestamp"  = $Timestamp
}

$Body = @{
    action  = $Action
    payload = $Payload
}

$JsonBody = $Body | ConvertTo-Json -Compress
Write-Host "⚙️  Envoi de la commande '$Action' vers le Bridge..."
Write-Host "🔑 Signature : $Signature"
Write-Host "🧾 Message : $Message"

try {
    $response = Invoke-RestMethod -Uri $BridgeURL -Method Post -Headers $Headers -Body $JsonBody
    $json = $response | ConvertTo-Json -Depth 5
    Add-Content -Path $LogFile -Value "`n[$(Get-Date)] ✅ Réponse du Bridge ($Action) : $json"
    Write-Host "`n✅ Réponse du Bridge ($Action) :"
    Write-Host $json
} catch {
    Add-Content -Path $LogFile -Value "`n[$(Get-Date)] ❌ Erreur ($Action) : $($_.Exception.Message)"
    Write-Host "[❌] Erreur lors de la commande '$Action' : $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n==============================================="
Write-Host "✅ Commande terminée. Log : $LogFile"
Write-Host "==============================================="
