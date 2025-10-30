# ====================================================================
# ðŸŽ›ï¸ Cockpit.Notify.psm1 â€“ v2.1 SecureFeedback
# Objectif : Gestion des retours visuels et vocaux dâ€™Athena dans le Cockpit
# Auteur : Ariane V4 / Athena Core
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === RÃ©pertoires principaux ===
$RootDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogsDir   = Join-Path $RootDir "..\Logs"
$VoiceMod  = Join-Path $RootDir "Athena.Voice.psm1"
$WebRoot   = Join-Path $RootDir "..\WebUI"
$SignalFile = Join-Path $WebRoot "signal.json"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$NotifyLog = Join-Path $LogsDir "CockpitNotify.log"

# ====================================================================
# âœï¸ Fonction de log
# ====================================================================
function Write-NotifyLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $NotifyLog -Value "[$t] $Msg"
    Write-Host $Msg -ForegroundColor DarkGray
}

# ====================================================================
# ðŸŒˆ Couleurs et sons selon statut
# ====================================================================
function Get-CockpitColor {
    param([string]$Status)
    switch -Regex ($Status.ToUpper()) {
        "SUCCESS" { return "green" }
        "WARN"    { return "yellow" }
        "ERROR"   { return "red" }
        default   { return "blue" }
    }
}

# ====================================================================
# ðŸ§  Notification centrale
# ====================================================================
function Invoke-CockpitNotify {
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Status = "INFO"
    )

    # --- Conversion sÃ©curisÃ©e ---
    $msg = [string]$Message
    $state = [string]$Status.ToUpper()
    $color = Get-CockpitColor $state

    Write-NotifyLog "[$state] $msg"

    # === ðŸ”Š Retour vocal ===
    if (Test-Path $VoiceMod) {
        try {
            Import-Module $VoiceMod -Force -Global | Out-Null
            Speak-Athena -Text $msg
        } catch {
            Write-NotifyLog "âš ï¸ Erreur vocalisation : $($_.Exception.Message)"
        }
    }

    # === ðŸŒˆ Signal visuel cockpit ===
    try {
        $signal = @{
            time   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            status = $state
            color  = $color
            text   = $msg
        }
        $signal | ConvertTo-Json -Depth 3 | Out-File -FilePath $SignalFile -Encoding utf8
        Write-NotifyLog "Signal visuel envoyÃ© ($color)"
    } catch {
        Write-NotifyLog "âš ï¸ Erreur signal visuel : $($_.Exception.Message)"
    }

    # === â±ï¸ Animation tempo 1 s ===
    Start-Sleep -Seconds 1
    return $msg
}

# ====================================================================
# ðŸ”š Export
# ====================================================================
Export-ModuleMember -Function Invoke-CockpitNotify, Write-NotifyLog
Write-Host "ðŸŽ›ï¸ Module Cockpit.Notify.psm1 chargÃ© (v2.1-SecureFeedback)" -ForegroundColor Cyan



