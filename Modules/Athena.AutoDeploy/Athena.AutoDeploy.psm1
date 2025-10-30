# ====================================================================
# ðŸ§  Athena.AutoDeploy.psm1 â€“ v2.1-Full-Autonomous
# --------------------------------------------------------------------
# Auteur : Yoann Rousselle / Athena Core
# --------------------------------------------------------------------
# RÃ´le :
#   - VÃ©rifie lâ€™intÃ©gritÃ© des modules et scripts
#   - Restaure automatiquement depuis Backups_Clean
#   - CrÃ©e des snapshots compressÃ©s (Fastest)
#   - Informe SelfCoordinator / Watchdog / Cockpit
#   - Enregistre un rapport JSON dans Memory
#   - PrÃ©pare les hooks des Phases 35â€“37
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === RÃ©pertoires principaux =========================================
$RootDir      = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ModulesDir   = Join-Path $RootDir 'Modules'
$ScriptsDir   = Join-Path $RootDir 'Scripts'
$LogsDir      = Join-Path $RootDir 'Logs'
$MemoryDir    = Join-Path $RootDir 'Memory'
$BackupDir    = Join-Path $RootDir 'Backups_Clean'
$SnapshotDir  = Join-Path $RootDir 'Backups_Snapshots'

foreach ($p in @($LogsDir,$MemoryDir,$BackupDir,$SnapshotDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

$LogFile    = Join-Path $LogsDir 'AutoDeploy.log'
$ReportFile = Join-Path $MemoryDir 'AutoDeployReport.json'

# ====================================================================
# âœï¸ Log standardisÃ©
# ====================================================================
function Write-DeployLog {
    param([string]$Msg,[string]$Level='INFO')
    $t=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ”’ Calcul de hash SHA256
# ====================================================================
function Get-FileHash256 {
    param([string]$Path)
    try {
        if (!(Test-Path $Path)) { return 'MISSING' }
        $sha=[System.Security.Cryptography.SHA256]::Create()
        $bytes=[System.IO.File]::ReadAllBytes($Path)
        ($sha.ComputeHash($bytes)|ForEach-Object{ $_.ToString('x2') })-join ''
    } catch { 'ERROR' }
}

# ====================================================================
# ðŸ§© VÃ©rification dâ€™intÃ©gritÃ© complÃ¨te
# ====================================================================
function Test-AthenaIntegrity {
    Write-Host "`nðŸ§© VÃ©rification dâ€™intÃ©gritÃ© des modules..." -ForegroundColor Cyan
    $issues=@()
    foreach ($f in (Get-ChildItem $ModulesDir -Filter 'Athena.*.psm1')) {
        $hashNow=Get-FileHash256 $f.FullName
        $backup=Join-Path $BackupDir $f.Name
        if (Test-Path $backup) {
            $hashBackup=Get-FileHash256 $backup
            if ($hashNow -ne $hashBackup) {
                Write-DeployLog "âš ï¸ Module corrompu : $($f.Name)"
                $issues+=$f.FullName
            }
        }
    }

    if ($issues.Count -eq 0) {
        Write-Host "âœ… Tous les modules sont intÃ¨gres." -ForegroundColor Green
        Write-DeployLog "âœ… VÃ©rification intÃ©gritÃ© complÃ¨te : OK"
    } else {
        Write-Host "âŒ Modules Ã  restaurer : $($issues.Count)" -ForegroundColor Red
        foreach ($i in $issues){ Restore-AthenaModule -Path $i }
    }

    return $issues
}

# ====================================================================
# ðŸ§± Restauration automatique de module
# ====================================================================
function Restore-AthenaModule {
    param([string]$Path)
    $file=[System.IO.Path]::GetFileName($Path)
    $src=Join-Path $BackupDir $file
    if (Test-Path $src) {
        Copy-Item $src $Path -Force
        Write-DeployLog "ðŸ” Restauration : $file"
    } else {
        Write-DeployLog "âŒ Aucun backup trouvÃ© pour $file"
    }
}

# ====================================================================
# ðŸª¶ Snapshot complet
# ====================================================================
function Create-AthenaSnapshot {
    $date=(Get-Date -Format 'yyyyMMdd_HHmmss')
    $zipName="Athena_Snapshot_$date.zip"
    $zipPath=Join-Path $SnapshotDir $zipName
    Write-Host "ðŸ’¾ CrÃ©ation du snapshot complet..." -ForegroundColor Cyan
    try {
        Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
        [System.IO.Compression.ZipFile]::CreateFromDirectory(
            $RootDir,
            $zipPath,
            [System.IO.Compression.CompressionLevel]::Fastest,
            $false
        )
        Write-DeployLog "ðŸ“¦ Snapshot crÃ©Ã© : $zipName"
        return $zipPath
    } catch { 
        Write-DeployLog "âŒ Erreur crÃ©ation snapshot : $_"
        return $null
    }
}

# ====================================================================
# âš™ï¸ Routine principale AutoDeploy
# ====================================================================
function Invoke-AthenaAutoDeploy {
    param([switch]$ForceSnapshot)
    Write-Host "`nâš™ï¸ Lancement du cycle AutoDeploy..." -ForegroundColor Cyan
    Write-DeployLog "=== AutoDeploy lancÃ© $(Get-Date -Format u) ==="

    $issues = Test-AthenaIntegrity
    $snapshot = $null

    if ($ForceSnapshot -or $issues.Count -gt 0) {
        $snapshot = Create-AthenaSnapshot
    }

    $report = [ordered]@{
        Date        = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        IssuesCount = $issues.Count
        Snapshot    = if ($snapshot) { Split-Path $snapshot -Leaf } else { 'none' }
    }

    $report | ConvertTo-Json -Depth 3 | Out-File $ReportFile -Encoding UTF8
    Write-DeployLog "ðŸ§  Rapport sauvegardÃ© : $ReportFile"

    Send-AthenaDeployStatus -Status 'Completed'
    Write-Host "âœ… Cycle AutoDeploy terminÃ©." -ForegroundColor Green
}

# ====================================================================
# ðŸ”— Communication systÃ¨me / Cockpit
# ====================================================================
function Send-AthenaDeployStatus {
    param([string]$Status)
    try {
        if (Get-Command Update-AthenaStatus -ErrorAction SilentlyContinue) {
            Update-AthenaStatus -Module 'AutoDeploy' -Status $Status
        }
        elseif (Get-Command Send-HybridSignal -ErrorAction SilentlyContinue) {
            Send-HybridSignal -Channel 'AutoDeploy' -Payload @{ State=$Status }
        }
        elseif (Get-Command Invoke-CockpitBroadcast -ErrorAction SilentlyContinue) {
            Invoke-CockpitBroadcast -Title 'AutoDeploy' -Message "Cycle $Status" -Type 'success'
        }
        else {
            Write-DeployLog 'â„¹ï¸ Aucun canal de notification dÃ©tectÃ©.'
        }
    } catch { Write-DeployLog "âŒ Erreur notification : $_" }
}

# ====================================================================
# ðŸ§  Hooks Phases 35â€“37
# ====================================================================
#region Phase35_SelfBuilder
# GÃ©nÃ©ration automatique des modules manquants (SelfBuilder)
#endregion
#region Phase36_HybridSync
# Synchronisation distante des sauvegardes via rÃ©seau sÃ©curisÃ©
#endregion
#region Phase37_SelfEvolution
# Adaptation dynamique des seuils de restauration selon stabilitÃ©
#endregion

# ====================================================================
# ðŸ”š Export
# ====================================================================
Export-ModuleMember -Function `
    Invoke-AthenaAutoDeploy, Test-AthenaIntegrity, Restore-AthenaModule, `
    Create-AthenaSnapshot, Send-AthenaDeployStatus, Write-DeployLog

Write-Host "ðŸ§  Module Athena.AutoDeploy.psm1 chargÃ© (v2.1-Full-Autonomous)." -ForegroundColor Cyan
Write-DeployLog "Module AutoDeploy v2.1-Full-Autonomous chargÃ©."
# ====================================================================


