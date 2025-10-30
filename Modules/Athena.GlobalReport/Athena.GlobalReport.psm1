# =====================================================================
# ðŸ—Ž Athena.GlobalReport.psm1 â€“ Rapport global dâ€™Athena
# Version : v1.2-stable
# =====================================================================
# Objectif :
#   - Fusionner toutes les donnÃ©es du cycle (Learning, Analytics, Logs)
#   - Calculer un score global consolidÃ©
#   - GÃ©nÃ©rer un rapport JSON + texte lisible dans le Cockpit
# =====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# --- Dossiers principaux ---
$ModuleDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleDir
$LogsDir     = Join-Path $RootDir "Logs"
$MemoryDir   = Join-Path $RootDir "Memory"

$SummaryFile   = Join-Path $MemoryDir "DailySummary.json"
$LearningFile  = Join-Path $MemoryDir "LearningHistory.json"
$GlobalJSON    = Join-Path $MemoryDir "GlobalReport.json"
$GlobalTXT     = Join-Path $MemoryDir "GlobalReport.txt"

# ---------------------------------------------------------------------
function Write-GlobalReportLog {
    param([string]$Message)
    Write-Host "ðŸ—Ž $Message" -ForegroundColor Cyan
}

# ---------------------------------------------------------------------
function Invoke-AthenaGlobalReport {
    Write-GlobalReportLog "GÃ©nÃ©ration du rapport global dâ€™Athena en cours..."

    $report = [ordered]@{
        Date          = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        IA_Mode       = $global:ArianeIADriver
        Score_Global  = 0
        CPU_Load      = $null
        RAM_Free      = $null
        Logs          = @()
        Recommandation = ""
    }

    # --- Lecture du DailySummary (analyse globale du jour) ---
    if (Test-Path $SummaryFile) {
        try {
            $daily = Get-Content $SummaryFile -Raw | ConvertFrom-Json
            $report.CPU_Load = $daily.CPU_Load
            $report.RAM_Free = $daily.RAM_Free
            $report.Score_Global = [math]::Max($report.Score_Global, $daily.PerformanceScore)
            $report.Logs += "ðŸ§  Analyse du jour : Score=$($daily.PerformanceScore)%"
        } catch {
            $report.Logs += "âš ï¸ Erreur lecture DailySummary : $_"
        }
    } else {
        $report.Logs += "âš ï¸ Aucun DailySummary trouvÃ©."
    }

    # --- Lecture de lâ€™historique dâ€™apprentissage ---
    if (Test-Path $LearningFile) {
        try {
            $learn = Get-Content $LearningFile -Raw | ConvertFrom-Json
            $last = $learn | Select-Object -Last 1
            $report.Score_Global = [math]::Round(($report.Score_Global + $last.LearningScore) / 2, 2)
            $report.Logs += "ðŸ“ˆ Dernier score dâ€™apprentissage : $($last.LearningScore)%"
        } catch {
            $report.Logs += "âš ï¸ Erreur lecture LearningHistory : $_"
        }
    } else {
        $report.Logs += "âš ï¸ Aucun historique dâ€™apprentissage trouvÃ©."
    }

    # --- Lecture des logs critiques (SelfRepair, Watchdog) ---
    $criticalLogs = @("SelfRepair.log", "Watchdog.log")
    foreach ($file in $criticalLogs) {
        $path = Join-Path $LogsDir $file
        if (Test-Path $path) {
            $lines = Get-Content $path -Tail 10
            $report.Logs += "ðŸ§© Extrait de $file :"
            $report.Logs += $lines
        }
    }

    # --- GÃ©nÃ©ration dâ€™une recommandation selon le score final ---
    if ($report.Score_Global -ge 80) {
        $report.Recommandation = "ðŸ’š SystÃ¨me stable et optimisÃ©."
    } elseif ($report.Score_Global -ge 60) {
        $report.Recommandation = "ðŸŸ¡ SystÃ¨me fonctionnel avec quelques rÃ©serves."
    } else {
        $report.Recommandation = "ðŸ”´ Anomalies dÃ©tectÃ©es â€“ relancer un cycle SelfRepair complet."
    }

    # --- Sauvegarde des rapports ---
    try {
        $report | ConvertTo-Json -Depth 6 | Set-Content -Path $GlobalJSON -Encoding UTF8
        $report.Logs -join "`n" | Set-Content -Path $GlobalTXT -Encoding UTF8
        Write-GlobalReportLog "âœ… Rapport global sauvegardÃ© dans :"
        Write-GlobalReportLog "   JSON : $GlobalJSON"
        Write-GlobalReportLog "   TXT  : $GlobalTXT"
    } catch {
        Write-Warning "âŒ Erreur lors de la sauvegarde du rapport global : $_"
    }

    # --- Affichage synthÃ©tique ---
    Write-Host "`nðŸ“Š Rapport global Athena" -ForegroundColor Yellow
    Write-Host "------------------------------------------"
    Write-Host "ðŸ“… Date : $($report.Date)"
    Write-Host "ðŸ¤– Mode IA : $($report.IA_Mode)"
    Write-Host "ðŸ’» CPU : $($report.CPU_Load)% | RAM libre : $($report.RAM_Free) MB"
    Write-Host "ðŸ Score final : $($report.Score_Global)%"
    Write-Host "ðŸ§­ Recommandation : $($report.Recommandation)"
    Write-Host "------------------------------------------`n"
}

Export-ModuleMember -Function Invoke-AthenaGlobalReport
Write-Host "ðŸ—Ž Module Athena.GlobalReport chargÃ© (v1.2-stable)."




