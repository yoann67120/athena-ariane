# ====================================================================
# ðŸ©º Athena.Diagnostic.psm1 â€“ Diagnostic systÃ¨me rapide
# ====================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

function Invoke-AthenaDiagnostic {
    Write-Host "ðŸ“‹ DÃ©marrage du diagnostic systÃ¨me..." -ForegroundColor Cyan
    $modules = Get-Module | Where-Object { $_.Name -like "Athena*" -or $_.Name -like "Ariane*" }
    $count   = $modules.Count
    Write-Host "âœ… $count modules actifs :" -ForegroundColor Green
    foreach ($m in $modules) {
        Write-Host "   â†’ $($m.Name)"
    }
    return "Diagnostic terminÃ© : $count modules dÃ©tectÃ©s."
}

Export-ModuleMember -Function Invoke-AthenaDiagnostic
Write-Host "ðŸ©º Athena.Diagnostic.psm1 chargÃ©." -ForegroundColor Cyan





