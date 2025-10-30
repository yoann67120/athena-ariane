# ====================================================================
# ðŸ—“ï¸ Athena.AutoPlanner.psm1 â€“ Planification autonome dâ€™Athena
# Version : v1.3-stable (Cycle Cognitif Complet + DÃ©tection Anomalies)
# ====================================================================
# Objectif :
#   - Lire les derniers rapports (GlobalReport, DailySummary, LearningHistory)
#   - DÃ©terminer les prochaines actions Ã  planifier automatiquement
#   - Sauvegarder le plan dâ€™action dans Data\GPT\NextPlan.json
#   - PrÃ©parer le cycle suivant dâ€™Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Dossiers principaux ---
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$DataDir    = Join-Path $RootDir "Data\GPT"

if (!(Test-Path $DataDir)) { New-Item -ItemType Directory -Path $DataDir -Force | Out-Null }

$NextPlan = Join-Path $DataDir "NextPlan.json"
$GlobalReport = Join-Path $MemoryDir "GlobalReport.json"
$DailySummary = Join-Path $MemoryDir "DailySummary.json"
$LearningHistory = Join-Path $MemoryDir "LearningHistory.json"

# --------------------------------------------------------------------
function Write-PlanLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "ðŸ—“ï¸ $Msg"
    Add-Content -Path (Join-Path $LogsDir "AutoPlanner.log") -Value "[$t][$Level] $Msg"
}

# --------------------------------------------------------------------
function Invoke-AthenaAutoPlanner {
    Write-PlanLog "ðŸ§­ GÃ©nÃ©ration du plan autonome Athena..."

    $plan = [ordered]@{
        Date        = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Mode        = $global:ArianeIADriver
        NextActions = @()
        Priority    = "Normal"
        Commentaire = ""
    }

    # --- Lecture des rapports existants ---
    try {
        $globalData = if (Test-Path $GlobalReport) { Get-Content $GlobalReport -Raw | ConvertFrom-Json } else { $null }
        $dailyData  = if (Test-Path $DailySummary) { Get-Content $DailySummary -Raw | ConvertFrom-Json } else { $null }
        $learnData  = if (Test-Path $LearningHistory) { Get-Content $LearningHistory -Raw | ConvertFrom-Json } else { @() }
    } catch {
        Write-PlanLog "âš ï¸ Erreur lecture rapports : $_" "WARN"
    }

    # --- Analyse des indicateurs ---
    $score = 0
    if ($globalData) { $score = [double]$globalData.Score_Global }
    elseif ($dailyData) { $score = [double]$dailyData.PerformanceScore }
    elseif ((@($learnData).Count) -gt 0) { $score = [double]($learnData | Select-Object -Last 1).LearningScore }

    Write-PlanLog "ðŸ“Š Score actuel dâ€™Athena : $score%"

    # --- Construction dynamique du plan ---
    if ($score -lt 50) {
        $plan.NextActions += "Relancer un cycle complet de SelfRepair"
        $plan.NextActions += "Forcer un diagnostic Cognition + Watchdog"
        $plan.Priority = "Haute"
        $plan.Commentaire = "Score faible dÃ©tectÃ©. Risque dâ€™anomalies persistantes."
    } elseif ($score -lt 75) {
        $plan.NextActions += "Effectuer un cycle de Learning et Analytics"
        $plan.NextActions += "Mettre Ã  jour la mÃ©moire cognitive"
        $plan.Commentaire = "SystÃ¨me stable mais amÃ©liorable."
    } else {
        $plan.NextActions += "Cycle de maintenance lÃ©ger"
        $plan.NextActions += "Synchroniser Cockpit et mÃ©moire"
        $plan.Commentaire = "SystÃ¨me optimal â€“ planification prÃ©ventive uniquement."
    }

    # --- Actions de suivi global ---
    $plan.NextActions += "Mettre Ã  jour le rapport global"
    $plan.NextActions += "ExÃ©cuter Cockpit.AutoLink pour actualisation visuelle"
    $plan.NextActions += "Sauvegarder le contexte cognitif"
    $plan.NextActions += "PrÃ©parer le prochain cycle dâ€™observation (Invoke-AthenaCognition)"

    # --- Sauvegarde du plan ---
    try {
        $plan | ConvertTo-Json -Depth 5 | Set-Content -Path $NextPlan -Encoding UTF8
        Write-PlanLog "âœ… Nouveau plan autonome sauvegardÃ© : $NextPlan"
    } catch {
        Write-PlanLog "âŒ Erreur de sauvegarde du plan : $_" "ERROR"
    }

    # --- RÃ©capitulatif console ---
    Write-Host "`nðŸ“… Planification automatique Athena" -ForegroundColor Yellow
    Write-Host "--------------------------------------------"
    Write-Host "ðŸ•’ Date : $($plan.Date)"
    Write-Host "ðŸ¤– Mode IA : $($plan.Mode)"
    Write-Host "ðŸ Score global : $score%"
    Write-Host "ðŸ“Œ PrioritÃ© : $($plan.Priority)"
    Write-Host "ðŸ§© Prochaines actions :"
    foreach ($a in $plan.NextActions) { Write-Host "   - $a" }
    Write-Host "--------------------------------------------`n"
}

Export-ModuleMember -Function Invoke-AthenaAutoPlanner, Write-PlanLog
Write-Host "âœ… Module Athena.AutoPlanner chargÃ© (v1.3-stable)."




