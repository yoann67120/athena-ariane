# ====================================================================
# 🤖 Athena.Fallback.psm1 – v1.0 Stable
# Auteur : Yoann Rousselle / Projet Ariane V4
# Description :
#   - Gère les intentions non reconnues
#   - Enregistre le texte dans un fichier d’apprentissage
#   - Envoie un retour au Hub et au Cockpit
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Dossiers ===
$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir "Logs"
$MemoryDir = Join-Path $RootDir "Memory"
$InboxDir  = Join-Path $RootDir "Server\Memory\InboxGPT"

foreach ($d in @($LogsDir,$MemoryDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$LogFile   = Join-Path $LogsDir "Fallback.log"
$UnknownFile = Join-Path $MemoryDir "UnknownIntents.json"

# --------------------------------------------------------------------
function Write-FallbackLog {
    param([string]$Msg,[string]$Level="INFO")
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$time][$Level] $Msg"
    Write-Host "[$Level] $Msg"
}

# --------------------------------------------------------------------
function Invoke-AthenaFallback {
    param(
        [string]$Intent = "unknown",
        [hashtable]$Payload = @{}
    )

    Write-FallbackLog "Intent non reconnu : $Intent"

    # Enregistre dans le fichier des intentions inconnues
    $entry = [ordered]@{
        timestamp = (Get-Date).ToString("s")
        intent    = $Intent
        payload   = $Payload
    }

    $data = @()
    if (Test-Path $UnknownFile) {
        try { $data = Get-Content -Path $UnknownFile -Raw | ConvertFrom-Json } catch { $data = @() }
    }
    $data += $entry
    $data | ConvertTo-Json -Depth 4 | Out-File -FilePath $UnknownFile -Encoding UTF8

    # Envoi d’un feedback vers le Hub
    try {
        if (Get-Command Send-AthenaResult -ErrorAction SilentlyContinue) {
            Send-AthenaResult -Label "UnknownIntent" -Content @{ intent = $Intent; status = "unknown" }
        }
    } catch {
        Write-FallbackLog "Erreur Send-AthenaResult : $_" "WARN"
    }

    # Réponse utilisateur (vocale ou console)
    $response = "Je n’ai pas compris cette demande, mais je l’ai enregistrée pour apprentissage."
    Write-Host "🤔 $response" -ForegroundColor Yellow

    return @{
        intent = $Intent
        status = "unknown"
        message = $response
        time = (Get-Date).ToString("s")
    } | ConvertTo-Json -Depth 4
}

# --------------------------------------------------------------------
Export-ModuleMember -Function Invoke-AthenaFallback
Write-Host "🤖 Module Athena.Fallback.psm1 chargé (v1.0 Stable)" -ForegroundColor Green
Write-FallbackLog "Module loaded (v1.0 Stable)."


