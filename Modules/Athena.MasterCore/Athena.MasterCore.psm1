# ====================================================================
# ðŸ§  Athena.MasterCore.psm1
# Version : v1.0 â€“ Cycle Principal UnifiÃ©
# ====================================================================

function Invoke-AthenaMasterCycle {
    <#
        .SYNOPSIS
            ExÃ©cute le cycle principal dâ€™Athena :
            - vÃ©rifie les sous-modules essentiels
            - lance les routines dâ€™apprentissage, dâ€™optimisation et de rapport
            - renvoie un statut global pour le Watchdog
    #>

    $RootDir  = "$env:ARIANE_ROOT"
    $LogsDir  = Join-Path $RootDir "Logs"
    $LogFile  = Join-Path $LogsDir "Athena_MasterCore_Daily.log"

    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')] ðŸ§  DÃ©but du cycle principal global."

    try {
        # --- 1ï¸âƒ£ VÃ©rification des modules critiques ---
        $CoreModules = @(
            "Athena.AutoRepair.psm1",
            "Athena.AutoLearning.psm1",
            "Athena.AutoHarmony.psm1",
            "Athena.AutoOptimize.psm1",
            "Athena.AutoReport.psm1"
        )

        foreach ($mod in $CoreModules) {
            $path = Join-Path (Join-Path $RootDir "Modules") $mod
            if (Test-Path $path) {
                Import-Module $path -Force -Global
                Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')] âœ… Module $mod chargÃ©."
            } else {
                Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')] âš ï¸ Module $mod introuvable."
            }
        }

        # --- 2ï¸âƒ£ Lancement des routines principales ---
        if (Get-Command Invoke-AthenaAutoLearning -ErrorAction SilentlyContinue) {
            Invoke-AthenaAutoLearning
            Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')] ðŸ” Apprentissage quotidien exÃ©cutÃ©."
        }

        if (Get-Command Invoke-AthenaAutoRepair -ErrorAction SilentlyContinue) {
            Invoke-AthenaAutoRepair
            Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')] ðŸ”§ RÃ©paration automatique exÃ©cutÃ©e."
        }

        if (Get-Command Invoke-AthenaAutoHarmony -ErrorAction SilentlyContinue) {
            Invoke-AthenaAutoHarmony
            Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')] ðŸ’« Harmonisation du systÃ¨me effectuÃ©e."
        }

        if (Get-Command Invoke-AthenaAutoOptimize -ErrorAction SilentlyContinue) {
            Invoke-AthenaAutoOptimize
            Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')] âš™ï¸ Optimisation terminÃ©e."
        }

        if (Get-Command Invoke-AthenaAutoReport -ErrorAction SilentlyContinue) {
            Invoke-AthenaAutoReport
            Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')] ðŸ§¾ Rapport gÃ©nÃ©rÃ©."
        }

        Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')] âœ… Cycle principal terminÃ© avec succÃ¨s."
        return $true
    }
    catch {
        Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')] âŒ Erreur fatale : $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function *

