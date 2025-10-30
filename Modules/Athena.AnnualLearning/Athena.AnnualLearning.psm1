# ====================================================================
# ðŸ“˜ Athena.AnnualLearning.psm1 â€“ v1.0-OmniAdaptive-Final
# ====================================================================
# Objectif :
#   Fusionner tous les rapports mensuels de lâ€™annÃ©e courante pour crÃ©er :
#     â€¢ Archive\LearningHistory_<YYYY>.md  (rapport lisible)
#     â€¢ Archive\LearningHistory_<YYYY>.json (donnÃ©es analytiques)
#
#   Inclut :
#     - pondÃ©ration annuelle des modules
#     - calcul de progression des scores
#     - dÃ©tection des tendances
#     - sÃ©curitÃ© : FIGÃ‰, lecture seule sur les sources
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# FIGÃ‰ : interdit de rÃ©gÃ©nÃ©ration automatique par SelfRepair
Set-Variable -Name "Ariane_FrozenModule" -Value $true -Scope Global

# === Chemins ===
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$ArchiveDir = Join-Path $RootDir "Archive"
$LogsDir    = Join-Path $RootDir "Logs"
$LogFile    = Join-Path $LogsDir "AthenaAnnualLearning.log"

foreach ($p in @($ArchiveDir,$LogsDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# === Variables de lâ€™annÃ©e ===
$year = (Get-Date).Year
$pattern = "MonthlyLearning_" + $year + "*"
$yearFolder = Join-Path $ArchiveDir ("AnnualLearning_" + $year)
if (!(Test-Path $yearFolder)) { New-Item -ItemType Directory -Path $yearFolder | Out-Null }

function Write-Log($msg,[string]$level="INFO"){
    $t=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $LogFile -Value "[$t][$level] $msg"
}

Write-Host "`nðŸ“˜ DÃ©marrage du rapport annuel $year..." -ForegroundColor Cyan
Write-Log "=== Rapport annuel $year lancÃ© ==="

# --------------------------------------------------------------------
# ðŸ” Collecte des rapports mensuels
# --------------------------------------------------------------------
$monthlyDirs = Get-ChildItem -Path $ArchiveDir -Directory | Where-Object Name -like $pattern
if (-not $monthlyDirs) {
    Write-Warning "Aucune archive mensuelle trouvÃ©e."
    Write-Log "Aucune archive mensuelle trouvÃ©e pour $year"
    return
}

$allScores = @()
$allModules = @{}
$allRules = @()
foreach ($dir in $monthlyDirs) {
    $mdFile = Get-ChildItem -Path $dir.FullName -Filter "LearningHistory_*.md" -ErrorAction SilentlyContinue | Select-Object -First 1
    $jsonFiles = Get-ChildItem -Path $dir.FullName -Filter "*.json" -ErrorAction SilentlyContinue
    foreach ($f in $jsonFiles) {
        try {
            $data = Get-Content $f.FullName -Raw | ConvertFrom-Json
            if ($data.Score) { $allScores += [double]$data.Score }
            if ($data.Modules) {
                foreach ($m in $data.Modules.PSObject.Properties) {
                    if (-not $allModules.ContainsKey($m.Name)) { $allModules[$m.Name] = @() }
                    $allModules[$m.Name] += [double]$m.Value
                }
            }
            if ($f.Name -eq "AutoRules.json" -and $data) { $allRules += $data }
        } catch { Write-Log "Erreur lecture $($f.FullName)" "WARN" }
    }
}

# --------------------------------------------------------------------
# ðŸ“ˆ Calcul des statistiques annuelles
# --------------------------------------------------------------------
$avgScore = if ($allScores.Count -gt 0) { [math]::Round(($allScores | Measure-Object -Average).Average,2) } else { 0 }
$moduleStats = @{}
foreach ($k in $allModules.Keys) {
    $v = ($allModules[$k] | Measure-Object -Average).Average
    $moduleStats[$k] = [math]::Round($v,3)
}
$topModules = $moduleStats.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10
$totalRules = $allRules.Count

# --------------------------------------------------------------------
# ðŸ§  DÃ©tection de tendances (croissance, stabilitÃ©, anomalie)
# --------------------------------------------------------------------
function Get-Trend {
    param([double[]]$values)
    if ($values.Count -lt 2) { return "Stable" }
    $delta = $values[-1] - $values[0]
    if ($delta -gt 5) { return "Croissance" }
    elseif ($delta -lt -5) { return "RÃ©gression" }
    else { return "Stable" }
}
$trend = Get-Trend -values $allScores

# --------------------------------------------------------------------
# ðŸ—‚ï¸ CrÃ©ation du rapport Markdown + JSON
# --------------------------------------------------------------------
$reportMd = Join-Path $yearFolder ("LearningHistory_" + $year + ".md")
$reportJson = Join-Path $yearFolder ("LearningHistory_" + $year + ".json")

$md = @"
# ðŸ§  Rapport Annuel d'Apprentissage â€“ $year

## ðŸ“Š SynthÃ¨se gÃ©nÃ©rale
- Score moyen annuel : **$avgScore %**
- Modules analysÃ©s : **$($moduleStats.Count)**
- RÃ¨gles gÃ©nÃ©rÃ©es : **$totalRules**
- Tendance globale : **$trend**

## ðŸ” Top 10 modules les plus fiables
$(if ($topModules.Count -gt 0) {
    ($topModules | ForEach-Object { "- $($_.Key) â†’ FiabilitÃ© moyenne $($_.Value)" }) -join "`n"
} else { "Aucun module analysÃ©." })

## ðŸ§  Historique des scores mensuels
$(if ($allScores.Count -gt 0) {
    ($i=1; $allScores | ForEach-Object { "- Mois $i : $($_) %" ; $i++ })
} else { "Aucune donnÃ©e de score enregistrÃ©e." })

---

_GÃ©nÃ©rÃ© automatiquement par Athena V4 le $(Get-Date -Format 'dd/MM/yyyy HH:mm')._
"@

$md | Out-File -FilePath $reportMd -Encoding utf8

$export = [PSCustomObject]@{
    Year = $year
    AverageScore = $avgScore
    Modules = $moduleStats
    TotalRules = $totalRules
    Trend = $trend
    Scores = $allScores
}
$export | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportJson -Encoding utf8

Write-Log "Rapport annuel gÃ©nÃ©rÃ© : $reportMd"
Write-Host "âœ… Rapport annuel crÃ©Ã© : $reportMd" -ForegroundColor Green

# --------------------------------------------------------------------
# ðŸ”’ SÃ©curitÃ© & prÃ©servation
# --------------------------------------------------------------------
if ($Global:AthenaSecurityLevel -ge 3) {
    Write-Host "âš ï¸ Mode DIEU actif : possibilitÃ© de purge et rÃ©Ã©criture." -ForegroundColor Red
    Write-Log "Mode Dieu : autorisation de nettoyage total."
    # Exemples : nettoyage sÃ©lectif (dÃ©sactivÃ© par dÃ©faut)
    # Remove-Item "$ArchiveDir\WeeklyLearning_*" -Recurse -Force
}

Write-Log "=== Fin du rapport annuel $year ==="
Write-Host "ðŸ“˜ Rapport annuel $year terminÃ© et archivÃ©." -ForegroundColor Cyan

Export-ModuleMember -Function *


