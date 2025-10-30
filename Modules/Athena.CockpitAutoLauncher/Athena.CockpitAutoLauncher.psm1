# ====================================================================
# ðŸš€ Athena.CockpitAutoLauncher.psm1 â€“ v1.0 VisualChain
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$WebUIDir   = Join-Path $RootDir "WebUI"
$BackupDir  = Join-Path $RootDir "WebUI_Backup"
$LogsDir    = Join-Path $RootDir "Logs"
$LogFile    = Join-Path $LogsDir "CockpitAutoLauncher.log"

foreach ($p in @($BackupDir,$LogsDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Write-CockpitLog {
    param([string]$Msg,[string]$L="INFO")
    $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$L] $Msg"
}

function Invoke-CockpitAutoLaunch {
    Write-Host "`nðŸš€ Lancement automatique du cockpit..." -ForegroundColor Cyan
    Write-CockpitLog "DÃ©marrage auto-lancement cockpit."

    $ts=(Get-Date).ToString("yyyyMMdd_HHmmss")
    $backupPath=Join-Path $BackupDir "WebUI_$ts"
    try {
        Copy-Item $WebUIDir $backupPath -Recurse -Force
        Write-CockpitLog "Sauvegarde crÃ©Ã©e : $backupPath"
    } catch {
        Write-CockpitLog "Erreur sauvegarde : $_" "WARN"
    }

    $indexPath = Join-Path $WebUIDir "index.html"
    if (Test-Path $indexPath) {
        try {
            Start-Process $indexPath
            Write-Host "ðŸŒ Cockpit ouvert dans le navigateur." -ForegroundColor Green
            Write-CockpitLog "Cockpit ouvert ($indexPath)"
        } catch {
            Write-Host "âš ï¸ Erreur ouverture cockpit : $_"
            Write-CockpitLog "Erreur ouverture cockpit : $_" "ERROR"
        }
    } else {
        Write-Host "âŒ index.html introuvable dans WebUI." -ForegroundColor Red
        Write-CockpitLog "index.html introuvable."
    }

    Write-CockpitLog "Fin auto-lancement cockpit."
}

Export-ModuleMember -Function Invoke-CockpitAutoLaunch
Write-Host "ðŸš€ Module CockpitAutoLauncher chargÃ© (v1.0 VisualChain)" -ForegroundColor Cyan


