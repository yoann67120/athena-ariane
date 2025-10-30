# ====================================================================
# ðŸ¤– Athena.Integrator.psm1 â€“ Auto-intÃ©gration du cycle dâ€™optimisation
# ====================================================================
# Objectif :
#   - VÃ©rifie si Start-AthenaDaily.ps1 contient les lignes dâ€™optimisation
#   - Si non, les ajoute automatiquement en fin de fichier
#   - Garantit que la Phase 18 (AutoOptimize + Security) sâ€™exÃ©cute chaque nuit
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir   = Split-Path -Parent $PSScriptRoot
$MainFile  = Join-Path $RootDir "Start-AthenaDaily.ps1"
$LogsDir   = Join-Path $RootDir "Logs"
$LogFile   = Join-Path $LogsDir "AthenaIntegrator.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-AthenaIntegratorLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t] $Msg"
}

function Invoke-AthenaIntegrator {
    Write-Host "`nðŸ¤– VÃ©rification de Start-AthenaDaily.ps1..." -ForegroundColor Cyan
    Write-AthenaIntegratorLog "=== VÃ©rification de Start-AthenaDaily.ps1 ==="

    if (!(Test-Path $MainFile)) {
        Write-Warning "âš ï¸ Fichier Start-AthenaDaily.ps1 introuvable."
        Write-AthenaIntegratorLog "Fichier introuvable : $MainFile"
        return
    }

    $content = Get-Content $MainFile -Raw

    if ($content -match "Invoke-AthenaOptimize") {
        Write-Host "âœ… Lignes dÃ©jÃ  prÃ©sentes, aucune action requise." -ForegroundColor Green
        Write-AthenaIntegratorLog "Aucune modification nÃ©cessaire (dÃ©jÃ  prÃ©sent)."
    }
    else {
        Write-Host "ðŸ§  Ajout automatique des lignes dâ€™optimisation..." -ForegroundColor Yellow
        Add-Content -Path $MainFile -Value "`n# === Phase 18 : Optimisation + SÃ©curitÃ© ==="
        Add-Content -Path $MainFile -Value "Import-Module .\Modules\Athena.AutoOptimize.psm1 -Force -Global"
        Add-Content -Path $MainFile -Value "Import-Module .\Modules\Athena.Security.psm1 -Force -Global"
        Add-Content -Path $MainFile -Value "Invoke-AthenaOptimize"
        Add-Content -Path $MainFile -Value "Invoke-AthenaSecurity"
        Write-Host "âœ… IntÃ©gration rÃ©ussie : les lignes ont Ã©tÃ© ajoutÃ©es." -ForegroundColor Green
        Write-AthenaIntegratorLog "Lignes ajoutÃ©es automatiquement Ã  $MainFile."
    }

    Write-Host "ðŸ—‚ï¸ Log : $LogFile"
}

Export-ModuleMember -Function Invoke-AthenaIntegrator




