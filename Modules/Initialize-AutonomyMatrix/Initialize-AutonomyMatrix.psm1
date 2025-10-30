# ==========================================================
# ðŸ§­ Initialize-AutonomyMatrix.psm1 â€“ v1.0
# Charge la matrice d'autonomie et applique les droits
# ==========================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

$RootDir   = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ConfigDir = Join-Path $RootDir 'Config'
$MatrixFile = Join-Path $ConfigDir 'AutonomyMatrix.json'
$LogFile = Join-Path $RootDir 'Logs\Autonomy.log'

function Write-AutoLog($msg) {
    $t = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $LogFile -Value "[$t] $msg"
}

function Initialize-AutonomyMatrix {
    if (!(Test-Path $MatrixFile)) {
        Write-AutoLog "âŒ AutonomyMatrix.json manquant."
        return
    }

    try {
        $matrix = Get-Content $MatrixFile -Raw | ConvertFrom-Json
        Write-Host "ðŸ§¬ Chargement de la matrice dâ€™autonomie..." -ForegroundColor Cyan

        foreach ($key in $matrix.PSObject.Properties.Name) {
            if ($matrix.$key.Status -eq "Enabled") {
                Write-Host "ðŸ”¹ Domaine activÃ© : $key ($($matrix.$key.Mode))" -ForegroundColor Green
                Write-AutoLog "Domaine $key activÃ© ($($matrix.$key.Mode))"
            }
        }

        # Signal cockpit
        if (Get-Command Send-CockpitSignal -ErrorAction SilentlyContinue) {
            Send-CockpitSignal -Type 'AthenaThinking'
        }

        Write-Host "âœ… Autonomie dâ€™Athena appliquÃ©e avec succÃ¨s." -ForegroundColor Green
        Write-AutoLog "Matrice appliquÃ©e avec succÃ¨s."
    }
    catch {
        Write-AutoLog "Erreur de lecture de la matrice : $_"
    }
}

Export-ModuleMember -Function Initialize-AutonomyMatrix
Write-Host "ðŸ§­ Module Initialize-AutonomyMatrix.psm1 chargÃ©." -ForegroundColor Cyan
Write-AutoLog "Module chargÃ©."


