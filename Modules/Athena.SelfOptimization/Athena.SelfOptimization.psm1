# ====================================================================
# âš™ï¸ Athena.SelfOptimization.psm1 â€“ v1.0-Performance-Core
# --------------------------------------------------------------------
# Objectif :
#   Surveiller et optimiser automatiquement les performances du systÃ¨me.
#   Ajuste la frÃ©quence des tÃ¢ches, purge les logs et compresse la
#   mÃ©moire pour maintenir la stabilitÃ© dâ€™Athena.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === RÃ©pertoires ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ConfigDir  = Join-Path $RootDir "Config"
$LogFile    = Join-Path $LogsDir "SelfOptimization.log"
$PerfFile   = Join-Path $MemoryDir "PerformanceSnapshot.json"

foreach ($p in @($LogsDir,$MemoryDir,$ConfigDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Write-OptLog {
    param([string]$Msg,[string]$Level="INFO")
    $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# 1ï¸âƒ£ Analyse systÃ¨me
# ====================================================================
function Analyze-SystemLoad {
    <#
        Retourne un objet avec CPU, RAM, et espace disque libre.
    #>
    Write-OptLog "Analyse du systÃ¨me..."
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $ram = Get-CimInstance Win32_OperatingSystem
    $memFree = [math]::Round(($ram.FreePhysicalMemory / $ram.TotalVisibleMemorySize) * 100,2)
    $disk = Get-PSDrive C | Select-Object -ExpandProperty Free
    $diskGB = [math]::Round($disk/1GB,2)

    $snapshot=[pscustomobject]@{
        Date  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        CPU   = [math]::Round($cpu,2)
        RAM   = $memFree
        Disk  = $diskGB
    }

    $snapshot | ConvertTo-Json -Depth 3 | Out-File $PerfFile -Encoding utf8
    Write-OptLog "CPU: $($snapshot.CPU)% | RAM libre: $($snapshot.RAM)% | Disque libre: $($snapshot.Disk) Go"
    return $snapshot
}

# ====================================================================
# 2ï¸âƒ£ Ajustement des frÃ©quences de tÃ¢ches planifiÃ©es
# ====================================================================
function Adapt-SchedulerFrequency {
    <#
        Ajuste la frÃ©quence des tÃ¢ches selon la charge CPU/RAM.
    #>
    param([double]$CPU,[double]$RAM)

    Write-OptLog "Adaptation du planificateur : CPU=$CPU | RAM=$RAM"
    $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "Athena_*" }

    foreach ($t in $tasks) {
        if ($CPU -gt 85 -or $RAM -lt 10) {
            Write-OptLog "âš ï¸ Charge Ã©levÃ©e : report de la tÃ¢che $($t.TaskName)"
            Disable-ScheduledTask -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null
        }
        elseif ($CPU -lt 50 -and $RAM -gt 30) {
            Enable-ScheduledTask -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null
            Write-OptLog "âœ… RÃ©activation de la tÃ¢che $($t.TaskName)"
        }
    }
}

# ====================================================================
# 3ï¸âƒ£ Purge automatique des logs
# ====================================================================
function Purge-Logs {
    param([int]$Days=14)
    Write-OptLog "Nettoyage des logs vieux de plus de $Days jours..."
    $deleted = Get-ChildItem $LogsDir -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$Days) }
    foreach ($f in $deleted) {
        Remove-Item $f.FullName -Force
        Write-OptLog "ðŸ—‘ï¸ Suppression : $($f.Name)"
    }
}

# ====================================================================
# 4ï¸âƒ£ Optimisation mÃ©moire JSON
# ====================================================================
function Optimize-MemoryUsage {
    Write-OptLog "Compactage de la mÃ©moire..."
    $files = Get-ChildItem $MemoryDir -Filter "*.json"
    foreach ($f in $files) {
        try {
            $data = Get-Content $f.FullName -Raw | ConvertFrom-Json
            $data | ConvertTo-Json -Depth 6 | Out-File $f.FullName -Encoding utf8
        } catch {
            Write-OptLog "âš ï¸ Erreur JSON dans $($f.Name)" "WARN"
        }
    }
}

# ====================================================================
# 5ï¸âƒ£ Cycle complet
# ====================================================================
function Invoke-SelfOptimizationCycle {
    Write-Host "`nâš™ï¸ Lancement du cycle SelfOptimization..." -ForegroundColor Cyan
    Write-OptLog "=== DÃ©but SelfOptimization ==="

    $perf = Analyze-SystemLoad
    Adapt-SchedulerFrequency -CPU $perf.CPU -RAM $perf.RAM
    Purge-Logs -Days 14
    Optimize-MemoryUsage

    Write-OptLog "=== Fin SelfOptimization ==="
    Write-Host "âœ… Cycle SelfOptimization terminÃ©." -ForegroundColor Green
}

# ====================================================================
# ðŸ”š Exports publics
# ====================================================================
Export-ModuleMember -Function `
    Analyze-SystemLoad, `
    Adapt-SchedulerFrequency, `
    Purge-Logs, `
    Optimize-MemoryUsage, `
    Invoke-SelfOptimizationCycle

Write-Host "âš™ï¸ Module Athena.SelfOptimization.psm1 chargÃ© (v1.0-Performance-Core)." -ForegroundColor Cyan
Write-OptLog "Module SelfOptimization v1.0 chargÃ©."



