# ====================================================================
# ðŸ§  Memory.Analytics.psm1 â€“ Rapport de supervision automatique (Athena)
# Version : v1.3-stable (Cycle Cognition + SelfRepair + Learning)
# ====================================================================
# Objectif :
#   - Lire les logs et Ã©tats dâ€™Athena (Cognition, Learning, SelfRepair, Watchdog)
#   - GÃ©nÃ©rer un rÃ©sumÃ© global du dernier cycle autonome
#   - Sauvegarder dans Memory\DailySummary.json
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# --- Dossiers et fichiers principaux ---
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LogsDir     = Join-Path $ProjectRoot "Logs"
$MemoryDir   = Join-Path $ProjectRoot "Memory"
$SummaryFile = Join-Path $MemoryDir "DailySummary.json"

$CognitionLog = Join-Path $MemoryDir "Cognition.log"
$LearningLog  = Join-Path $MemoryDir "Learning.log"
$RepairLog    = Join-Path $LogsDir   "SelfRepair.log"
$WatchdogLog  = Join-Path $LogsDir   "Watchdog.log"

# --------------------------------------------------------------------
function Invoke-MemoryAnalytics {
    Write-Host "`nðŸ§  Analyse globale du cycle Athena en cours..." -ForegroundColor Cyan

    $summary = [ordered]@{
        Date       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        CPU_Load   = $null
        RAM_Free   = $null
        IA_Mode    = $global:ArianeIADriver
        PerformanceScore = 0
        Notes      = @()
    }

    # --- Lecture des journaux principaux ---
    $logs = @($CognitionLog, $LearningLog, $RepairLog, $WatchdogLog)
    $entries = @()
    foreach ($log in $logs) {
        if (Test-Path $log) {
            $lines = Get-Content $log -Tail 50 -ErrorAction SilentlyContinue
            $summary.Notes += "ðŸ“„ DerniÃ¨res lignes de $([IO.Path]::GetFileName($log)) :"
            $summary.Notes += $lines
            $entries += $lines
        }
    }

    # --- Analyse rapide des indicateurs dans les logs ---
    $errorCount  = ($entries | Where-Object { $_ -match "ERROR|âŒ" }).Count
    $warnCount   = ($entries | Where-Object { $_ -match "WARN|âš ï¸" }).Count
    $successCount = ($entries | Where-Object { $_ -match "âœ…" }).Count

    # --- Calcul dâ€™un score global de performance ---
    $summary.PerformanceScore = [math]::Max(0, 100 - ($errorCount * 8 + $warnCount * 4))
    $summary.Notes += "ðŸ“Š SynthÃ¨se : Erreurs=$errorCount | Avertissements=$warnCount | SuccÃ¨s=$successCount"
    $summary.Notes += "ðŸ§® Score global de performance : $($summary.PerformanceScore)%"

    # --- Tentative dâ€™extraction CPU/RAM depuis les logs de Cognition ---
    try {
        $cpuLine = ($entries | Select-String -Pattern "CPU=.*?%").Matches.Value | Select-Object -Last 1
        $ramLine = ($entries | Select-String -Pattern "RAM libre=.*?MB").Matches.Value | Select-Object -Last 1
        if ($cpuLine) { $summary.CPU_Load = ($cpuLine -replace "[^\d\.]", "") }
        if ($ramLine) { $summary.RAM_Free = ($ramLine -replace "[^\d\.]", "") }
    } catch {
        $summary.Notes += "âš ï¸ Impossible dâ€™extraire les donnÃ©es CPU/RAM."
    }

    # --- Sauvegarde JSON ---
    try {
        if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null }
        $summary | ConvertTo-Json -Depth 6 | Set-Content -Path $SummaryFile -Encoding UTF8
        Write-Host "âœ… Rapport cognitif global sauvegardÃ© : $SummaryFile" -ForegroundColor Green
    } catch {
        Write-Warning "âŒ Erreur lors de la sauvegarde du rapport : $_"
    }

    # --- Rapport console synthÃ©tique ---
    Write-Host "ðŸ“Š Score global : $($summary.PerformanceScore)% | Mode IA : $($summary.IA_Mode)" -ForegroundColor Yellow
    if ($summary.PerformanceScore -lt 50) {
        Write-Host "âš ï¸ Recommandation : relancer un cycle SelfRepair ou Cognition complet." -ForegroundColor Red
    } elseif ($summary.PerformanceScore -gt 80) {
        Write-Host "ðŸ’š SystÃ¨me stable et performant." -ForegroundColor Green
    } else {
        Write-Host "ðŸŸ¡ SystÃ¨me opÃ©rationnel avec rÃ©serves." -ForegroundColor Yellow
    }
}

Export-ModuleMember -Function Invoke-MemoryAnalytics
Write-Host "âœ… Module Memory.Analytics.psm1 chargÃ© (analyse automatique prÃªte)."



