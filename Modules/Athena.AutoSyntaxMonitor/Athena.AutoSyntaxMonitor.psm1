# ====================================================================
# Athena.AutoSyntaxMonitor.psm1
# Version : v1.0-LiveWatcher (2025-10-17)
# Objectif : Surveiller les nouveaux modules et appliquer automatiquement le correcteur syntaxique
# DÃ©pendance : Athena.ModuleSyntaxFix.psm1
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$Modules   = Join-Path $RootDir "Modules"
$LogFile   = Join-Path $RootDir "Logs\AutoSyntaxMonitor.log"

# --- Fonction de log ---
function Write-MonitorLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# --- Fonction : Appliquer le fix ---
function Invoke-SyntaxFix {
    try {
        Import-Module "$Modules\Athena.ModuleSyntaxFix.psm1" -Force -Global
        Write-MonitorLog "ðŸ§© Correcteur syntaxique lancÃ© automatiquement."
        Invoke-AthenaModuleSyntaxFix | Out-Null
        Write-MonitorLog "âœ… Correcteur terminÃ© avec succÃ¨s."
    } catch {
        Write-MonitorLog "âŒ Erreur durant le correcteur : $($_.Exception.Message)" "ERROR"
    }
}

# --- Fonction principale : surveillance ---
function Start-AthenaAutoSyntaxMonitor {
    [CmdletBinding()]
    param(
        [int]$IntervalSeconds = 15
    )

    Write-Host "ðŸ§  Surveillance des modules Athena activÃ©e..." -ForegroundColor Cyan
    Write-MonitorLog "=== DÃ©marrage du service AutoSyntaxMonitor ==="
    Write-MonitorLog "Dossier surveillÃ© : $Modules"

    $filter = "*.psm1"
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Modules
    $watcher.Filter = $filter
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

    Register-ObjectEvent $watcher Created -Action {
        $path = $Event.SourceEventArgs.FullPath
        Write-Host "ðŸ§© Nouveau module dÃ©tectÃ© : $path" -ForegroundColor Green
        Write-MonitorLog "Nouveau module dÃ©tectÃ© : $path"
        Start-Sleep -Seconds 1
        Invoke-SyntaxFix
    } | Out-Null

    Register-ObjectEvent $watcher Changed -Action {
        $path = $Event.SourceEventArgs.FullPath
        Write-Host "ðŸª¶ Modification dÃ©tectÃ©e : $path" -ForegroundColor Yellow
        Write-MonitorLog "Modification dÃ©tectÃ©e : $path"
        Start-Sleep -Seconds 1
        Invoke-SyntaxFix
    } | Out-Null

    # Boucle de maintien (veille passive)
    while ($true) {
        Start-Sleep -Seconds $IntervalSeconds
    }
}

Export-ModuleMember -Function Start-AthenaAutoSyntaxMonitor
Write-Host "ðŸ§© Module Athena.AutoSyntaxMonitor chargÃ© (v1.0-LiveWatcher)" -ForegroundColor Cyan
Write-MonitorLog "Module chargÃ© (v1.0-LiveWatcher)"


