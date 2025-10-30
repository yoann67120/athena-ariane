# ====================================================================
# ðŸ§  AutoLoader.psm1 â€“ Chargeur modulaire basique pour Ariane V4
# ====================================================================

function Load-AllModules {
    param(
        [string]$ModulesPath
    )

    Write-Host "ðŸ” Chargement automatique des modules..." -ForegroundColor Yellow

    # Charge tous les .psm1 sauf le noyau et AutoLoader lui-mÃªme
    Get-ChildItem -Path $ModulesPath -Filter *.psm1 -Recurse | ForEach-Object {
        $name = $_.Name
        if ($name -notmatch 'AutoLoader' -and $name -notmatch 'Core.psm1') {
            try {
                Import-Module $_.FullName -Force -WarningAction SilentlyContinue -ErrorAction Stop
                Write-Host "âœ… Module chargÃ© : $name" -ForegroundColor Cyan
            } catch {
                Write-Host "âŒ Erreur chargement module : $name ($($_.Exception.Message))" -ForegroundColor Red
            }
        }
    }

    Write-Host "ðŸ§© Tous les modules ont Ã©tÃ© parcourus." -ForegroundColor Green
}

Export-ModuleMember -Function Load-AllModules



