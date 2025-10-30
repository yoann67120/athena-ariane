# ====================================================================
# ðŸ§© Athena.Sleep.psm1 â€“ ContrÃ´le de mise en veille manuelle
# Version : v1.0â€“DreamSwitch-Edition
# ====================================================================
# Objectif :
#   - Offrir une commande pour endormir Athena Ã  la demande
#   - Fermer proprement lâ€™orchestrateur global
#   - Lancer ensuite le cycle de rÃªve (Start-AthenaDreamCycle.ps1)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$LogFile    = Join-Path $LogsDir "AthenaSleep.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-SleepLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t] $Msg"
}

# --------------------------------------------------------------------
# ðŸŒ™ Fonction principale
# --------------------------------------------------------------------
function Invoke-AthenaSleep {
    Write-Host "`nðŸŒ™ Mise en veille douce dâ€™Athena..." -ForegroundColor Magenta
    Write-SleepLog "Demande de mise en veille reÃ§ue."

    # --- Feedback visuel et sonore avant sommeil
    try {
        if (Get-Command Set-CockpitMood -ErrorAction SilentlyContinue) {
            Set-CockpitMood -Mood "attentive" -State "Concentration" -Message "PrÃ©paration Ã  la veille..."
            Start-Sleep -Seconds 1
            Set-CockpitMood -Mood "inquiÃ¨te" -State "Vigilance" -Message "Fermeture progressive des cycles..."
            Start-Sleep -Seconds 1
            Set-CockpitMood -Mood "satisfaite" -State "SÃ©rÃ©nitÃ©" -Message "EntrÃ©e en veille douce."
        }
        if (Get-Command Play-AthenaSound -ErrorAction SilentlyContinue) {
            [console]::beep(400,250); [console]::beep(300,200); [console]::beep(200,300)
        }
        if (Get-Command Invoke-AthenaVoice -ErrorAction SilentlyContinue) {
            Invoke-AthenaVoice -Text "Je passe en veille douce. Ã€ bientÃ´t." -Silent
        }
    } catch { Write-Warning "âš ï¸ Erreur pendant la sÃ©quence sensorielle de veille." }

    # --- Tentative dâ€™arrÃªt du FullCycle
    try {
        Get-Job | Where-Object { $_.Name -like "*AthenaFullCycle*" -or $_.Command -match "Start-AthenaFullCycle" } | ForEach-Object {
            Write-Host "ðŸ›‘ ArrÃªt du processus d'orchestration global : $($_.Id)" -ForegroundColor Yellow
            Stop-Job -Id $_.Id -Force
        }
        Write-SleepLog "Orchestrateur global arrÃªtÃ© proprement."
    } catch { Write-Warning "âš ï¸ Aucun orchestrateur dÃ©tectÃ© ou dÃ©jÃ  arrÃªtÃ©." }

    # --- Lancement du cycle de rÃªve
    try {
        $dream = Join-Path $RootDir "Start-AthenaDreamCycle.ps1"
        if (Test-Path $dream) {
            Write-Host "ðŸ’¤ Lancement du cycle de rÃªve nocturne..." -ForegroundColor Cyan
            & $dream
            Write-SleepLog "Cycle de rÃªve lancÃ©."
        } else {
            Write-Warning "âš ï¸ Script de rÃªve introuvable ($dream)"
            Write-SleepLog "Cycle de rÃªve non trouvÃ©."
        }
    } catch { Write-Warning "âš ï¸ Erreur lors du lancement du DreamCycle : $_" }
}

Export-ModuleMember -Function Invoke-AthenaSleep
Write-Host "ðŸ§© Athena.Sleep.psm1 chargÃ© (v1.0â€“DreamSwitch-Edition)" -ForegroundColor Magenta
Write-SleepLog "Module chargÃ© et prÃªt."




