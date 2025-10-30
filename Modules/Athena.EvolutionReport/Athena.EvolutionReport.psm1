# ====================================================================
# ðŸ“Š Athena.EvolutionReport.psm1 â€“ Rapport dâ€™Ã©volution automatique
# Version : v1.1-stable-safe
# Objectif : GÃ©nÃ©rer un rÃ©sumÃ© complet des Ã©volutions Ã  chaque cycle.
# AmÃ©liorations :
#   - SÃ©curisation des variables CPU et RAM
#   - Protection contre erreurs de fichiers manquants
#   - Journalisation plus claire
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir    = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ModulesDir = Join-Path $RootDir "Modules"
$ReportFile = Join-Path $MemoryDir "EvolutionReport.json"

# ====================================================================
# ðŸ§  Fonction principale
# ====================================================================
function Invoke-AthenaEvolutionReport {
    Write-Host "`nðŸ“Š GÃ©nÃ©ration du rapport dâ€™Ã©volution Athena..." -ForegroundColor Cyan

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $AutoPatchLog = Join-Path $LogsDir "AutoPatch.log"

    # ----------------------------------------------------------------
# âœ… SÃ©curisation CPU et RAM
# ----------------------------------------------------------------
try {
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time'
    $cpuLoad = [math]::Round(($cpu.CounterSamples.CookedValue), 2)
} catch {
    # MÃ©thode de secours
    try {
        $cpuLoad = [math]::Round((Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average, 2)
    } catch {
        $cpuLoad = "N/A"
    }
}

try {
    $mem = Get-CimInstance Win32_OperatingSystem
    $ramUsedPct = [math]::Round((($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize) * 100, 2)
} catch {
    $ramUsedPct = "N/A"
}
    # ----------------------------------------------------------------
    # ðŸ“¦ Modules crÃ©Ã©s / archivÃ©s
    # ----------------------------------------------------------------
    $created = @()
    $archived = @()

    if (Test-Path $AutoPatchLog) {
        $logLines = Get-Content $AutoPatchLog -ErrorAction SilentlyContinue
        $created = $logLines | Select-String -Pattern "CrÃ©ation ou mise Ã  jour du module expÃ©rimental" | ForEach-Object { ($_ -split ': ')[-1] }
        $archived = $logLines | Select-String -Pattern "archivÃ©" | ForEach-Object { ($_ -split ': ')[-1] }
    }

    # ----------------------------------------------------------------
    # ðŸ§¾ Structure du rapport
    # ----------------------------------------------------------------
    $report = [ordered]@{
        Date      = $timestamp
        CPU_Load  = "$cpuLoad %"
        RAM_Usage = "$ramUsedPct %"
        Modules   = @{
            Total    = (Get-ChildItem $ModulesDir -Filter *.psm1 -ErrorAction SilentlyContinue | Measure-Object).Count
            Created  = $created
            Archived = $archived
        }
        Logs      = @{
            AutoPatch_LastUpdate = if (Test-Path $AutoPatchLog) { (Get-Item $AutoPatchLog).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "Aucun log trouvÃ©" }
        }
    }

    # ----------------------------------------------------------------
    # ðŸ’¾ Sauvegarde du rapport JSON
    # ----------------------------------------------------------------
    try {
        $json = $report | ConvertTo-Json -Depth 5
        $json | Set-Content -Path $ReportFile -Encoding UTF8
        Write-Host "âœ… Rapport dâ€™Ã©volution sauvegardÃ© : $ReportFile" -ForegroundColor Green
    } catch {
        Write-Warning "âŒ Erreur lors de la sauvegarde du rapport : $_"
    }
}

# ----------------------------------------------------------------
# ðŸš€ Export & Confirmation
# ----------------------------------------------------------------
Export-ModuleMember -Function Invoke-AthenaEvolutionReport
Write-Host "âœ… Module Athena.EvolutionReport.psm1 v1.1 chargÃ© (rapport automatique prÃªt)."




