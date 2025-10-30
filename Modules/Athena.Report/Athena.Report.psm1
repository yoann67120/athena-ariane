# =====================================================================
# ðŸŒ… Athena.Report.psm1 â€“ Rapport de fin de cycle Athena
# Version : v1.2-stable (texte + vocal)
# =====================================================================
# Objectif :
#   - Lire les rapports finaux (GlobalReport, DailySummary, NextPlan)
#   - GÃ©nÃ©rer un rÃ©sumÃ© textuel complet du jour
#   - Lire le rapport Ã  voix haute si le module Voice est disponible
#   - Sauvegarder le rapport dans Logs\AthenaReport.log
# =====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Dossiers principaux ---
$ModuleDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleDir
$LogsDir     = Join-Path $RootDir "Logs"
$MemoryDir   = Join-Path $RootDir "Memory"
$DataDir     = Join-Path $RootDir "Data\GPT"

$GlobalReport = Join-Path $MemoryDir "GlobalReport.json"
$DailySummary = Join-Path $MemoryDir "DailySummary.json"
$NextPlan     = Join-Path $DataDir "NextPlan.json"
$ReportLog    = Join-Path $LogsDir "AthenaReport.log"

# --------------------------------------------------------------------
function Write-ReportLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $ReportLog -Value "[$t][$Level] $Msg"
    Write-Host "ðŸŒ… $Msg"
}

# --------------------------------------------------------------------
function Invoke-AthenaReport {
    Write-Host "`nðŸŒ… GÃ©nÃ©ration du rapport de fin de journÃ©e Athena..." -ForegroundColor Cyan

    $report = [ordered]@{
        Date   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        ModeIA = $global:ArianeIADriver
        Score  = 0
        Resume = ""
        Plan   = @()
    }

    # --- Lecture des rapports ---
    try {
        if (Test-Path $GlobalReport) {
            $globalData = Get-Content $GlobalReport -Raw | ConvertFrom-Json
            $report.Score = [math]::Round([double]$globalData.Score_Global,2)
            $report.Resume += "Score global : $($report.Score)%`n"
            $report.Resume += "Recommandation : $($globalData.Recommandation)`n"
        }
        if (Test-Path $DailySummary) {
            $dailyData = Get-Content $DailySummary -Raw | ConvertFrom-Json
            $report.Resume += "Dernier rÃ©sumÃ© de performance disponible.`n"
        }
        if (Test-Path $NextPlan) {
            $planData = Get-Content $NextPlan -Raw | ConvertFrom-Json
            $report.Plan = $planData.NextActions
            $report.Resume += "Plan suivant : $($planData.NextActions -join ', ')`n"
        }
    } catch {
        Write-ReportLog "âŒ Erreur lecture fichiers : $_" "ERROR"
    }

    # --- SynthÃ¨se du jour ---
    $textReport = @()
    $textReport += "=================== RAPPORT ATHENA ==================="
    $textReport += "ðŸ—“ï¸ Date : $($report.Date)"
    $textReport += "ðŸ¤– Mode IA : $($report.ModeIA)"
    $textReport += "ðŸ Score global : $($report.Score)%"
    $textReport += "-----------------------------------------------------"
    $textReport += $report.Resume
    $textReport += "-----------------------------------------------------"
    if ($report.Plan.Count -gt 0) {
        $textReport += "ðŸ“‹ Prochaines actions planifiÃ©es :"
        foreach ($a in $report.Plan) { $textReport += "   - $a" }
    } else {
        $textReport += "ðŸ“‹ Aucune action planifiÃ©e pour le moment."
    }
    $textReport += "====================================================="
    $textReportText = $textReport -join "`n"

    # --- Sauvegarde du rapport ---
    try {
        $textReportText | Set-Content -Path $ReportLog -Encoding UTF8
        Write-ReportLog "âœ… Rapport Athena sauvegardÃ© dans : $ReportLog"
    } catch {
        Write-ReportLog "âŒ Erreur sauvegarde rapport : $_" "ERROR"
    }

    # --- Lecture vocale (si Voice.psm1 est prÃ©sent) ---
    if (Get-Command -Name Invoke-VoiceSpeak -ErrorAction SilentlyContinue) {
        Write-Host "ðŸ”Š Lecture vocale du rÃ©sumÃ©..." -ForegroundColor Yellow
        $voiceText = "Rapport du jour : Score global $($report.Score) pour cent. $($globalData.Recommandation)"
        Invoke-VoiceSpeak -Text $voiceText
    } else {
        Write-Host "ðŸ—£ï¸ Aucun moteur vocal dÃ©tectÃ© â€“ lecture texte uniquement." -ForegroundColor DarkGray
    }

    # --- Affichage synthÃ©tique console ---
    Write-Host "`n$textReportText`n" -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-AthenaReport, Write-ReportLog
Write-Host "ðŸŒ… Module Athena.Report chargÃ© (v1.2-stable)."




