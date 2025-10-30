# ====================================================================
# ðŸ©º Athena.AutoRepair.psm1 â€“ RÃ©paration autonome
# Version : v1.0
# ====================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

function Invoke-AthenaAutoRepair {
    Write-Host "ðŸ› ï¸ Lancement du cycle de rÃ©paration automatique..." -ForegroundColor Cyan

    # Import du module de patch principal
    try {
        Import-Module "$PSScriptRoot\\AutoPatch.psm1" -Force -Global
        $result = Invoke-AutoPatch
        Write-Host "âœ… RÃ©paration effectuÃ©e via AutoPatch."
    } catch {
        Write-Warning "âš ï¸ Erreur pendant la rÃ©paration automatique : $_"
    }

    return "Cycle AutoRepair terminÃ©."
}

Export-ModuleMember -Function Invoke-AthenaAutoRepair
Write-Host "ðŸ©º Athena.AutoRepair.psm1 chargÃ©." -ForegroundColor Cyan




