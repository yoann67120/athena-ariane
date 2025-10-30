# ====================================================================
# ðŸ§© Ariane V4 â€“ Cockpit.Launcher.psm1
# Gestion du lancement et de lâ€™arrÃªt propre du Cockpit K2000
# Auteur : Athena Engine
# Version : 1.0-stable
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- DÃ©tection du rÃ©pertoire Modules ---
$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$CockpitData = Join-Path $ModuleDir "Cockpit.Data.psm1"
$CockpitUI   = Join-Path $ModuleDir "Cockpit.UI.psm1"

# --- VÃ©rifie la prÃ©sence des modules requis ---
if (!(Test-Path $CockpitData) -or !(Test-Path $CockpitUI)) {
    Write-Warning "âš ï¸ Modules Cockpit.Data ou Cockpit.UI introuvables."
    return
}

# ====================================================================
# ðŸš€ Fonction : Start-AthenaCockpit
# Lance le cockpit dans un job sÃ©parÃ©, Ã©vite les doublons.
# ====================================================================
function Start-AthenaCockpit {
    [CmdletBinding()]
    param()

    $existing = Get-Job -Name "AthenaCockpit" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "âš ï¸ Cockpit dÃ©jÃ  actif." -ForegroundColor Yellow
        return
    }

    Write-Host "ðŸ–¥ï¸ Lancement du Cockpit K2000..." -ForegroundColor Cyan

    Start-Job -Name "AthenaCockpit" -ScriptBlock {
        try {
            Import-Module $using:CockpitData -Force -ErrorAction Stop
            Import-Module $using:CockpitUI   -Force -ErrorAction Stop
            Write-Host "âœ… Cockpit initialisÃ© dans un job sÃ©parÃ©." -ForegroundColor Green
            Start-Sleep -Seconds 2
            while ($true) {
                Start-Sleep -Seconds 1
            }
        }
        catch {
            Write-Host "âŒ Erreur lors du lancement du cockpit : $_" -ForegroundColor Red
        }
    } | Out-Null
}

# ====================================================================
# ðŸ§¹ Fonction : Stop-AthenaCockpit
# Ferme proprement le cockpit et libÃ¨re le job associÃ©.
# ====================================================================
function Stop-AthenaCockpit {
    [CmdletBinding()]
    param()

    $job = Get-Job -Name "AthenaCockpit" -ErrorAction SilentlyContinue
    if ($job) {
        Stop-Job -Job $job -Force
        Remove-Job -Job $job
        Write-Host "ðŸ§¹ Cockpit arrÃªtÃ© proprement." -ForegroundColor Cyan
    }
    else {
        Write-Host "â„¹ï¸ Aucun cockpit actif Ã  arrÃªter." -ForegroundColor DarkGray
    }
}

# ====================================================================
# â™»ï¸ Fonction : Restart-AthenaCockpit
# Relance le cockpit proprement (utile aprÃ¨s crash ou mise Ã  jour).
# ====================================================================
function Restart-AthenaCockpit {
    [CmdletBinding()]
    param()
    Stop-AthenaCockpit
    Start-Sleep -Seconds 1
    Start-AthenaCockpit
}

# ====================================================================
# ðŸ“¦ Export des fonctions
# ====================================================================
Export-ModuleMember -Function Start-AthenaCockpit, Stop-AthenaCockpit, Restart-AthenaCockpit

Write-Host "ðŸ§© Cockpit.Launcher.psm1 chargÃ© (v1.0-stable)" -ForegroundColor Magenta



