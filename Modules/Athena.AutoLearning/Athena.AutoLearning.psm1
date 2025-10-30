# ====================================================================
# ðŸ§  Athena.AutoLearning.psm1 â€“ v3.2-IntegratedCore-FutureReady
# --------------------------------------------------------------------
# BasÃ© sur : v3.1-AutoFix Stable (Yoann Rousselle / Athena Core)
# AmÃ©liorations :
#   - Liaison SelfCoordinator / HybridLink / Watchdog
#   - SystÃ¨me de notification standardisÃ© (Send-AthenaLearningStatus)
#   - VÃ©rification dâ€™intÃ©gritÃ© pour AutoDeploy
#   - Hooks Phases 35â€“37 (SelfBuilder / HybridSync / SelfEvolution)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

$RootDir     = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$LogsDir     = Join-Path $RootDir 'Logs'
$MemoryDir   = Join-Path $RootDir 'Memory'
$LearningDir = Join-Path $MemoryDir 'Learning'
$LogFile     = Join-Path $LogsDir 'LearningEvolution.log'
$WeightsFile = Join-Path $LearningDir 'LearningWeights.json'
$HistoryFile = Join-Path $LearningDir 'LearningHistory.json'

foreach ($d in @($LogsDir, $MemoryDir, $LearningDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ====================================================================
# âœï¸ Journalisation
# ====================================================================
function Write-LearningLog {
    param([string]$Msg)
    $t = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $LogFile -Value "[$t] $Msg"
}

# ====================================================================
# ðŸ” Lecture et calcul du LearningIndex
# ====================================================================
function Compute-LearningIndex {
    if (!(Test-Path $HistoryFile)) { return 0 }
    try {
        $data = Get-Content $HistoryFile -Raw | ConvertFrom-Json
        $values = $data | ForEach-Object { $_.LearningIndex }
        if ($values.Count -eq 0) { return 0 }
        [math]::Round(($values | Measure-Object -Average).Average, 2)
    } catch { return 0 }
}

# ====================================================================
# ðŸ“ˆ Ajustement des pondÃ©rations Ã©motionnelles
# ====================================================================
function Update-LearningWeights {
    param([Hashtable]$Trends)
    $weights = @{
        Stress     = 0.5
        Serenite   = 0.5
        Fatigue    = 0.5
        Confiance  = 0.5
        Motivation = 0.5
    }
    if (Test-Path $WeightsFile) {
        try { $weights = Get-Content $WeightsFile -Raw | ConvertFrom-Json -AsHashtable } catch {}
    }
    foreach ($k in $Trends.Keys) {
        if ($weights.ContainsKey($k)) {
            $delta = switch ($Trends[$k]) {
                'hausse' { 0.05 }
                'baisse' { -0.05 }
                default  { 0 }
            }
            $weights[$k] = [math]::Min(1,[math]::Max(0,$weights[$k] + $delta))
        }
    }
    $weights | ConvertTo-Json -Depth 3 | Set-Content -Path $WeightsFile -Encoding UTF8
    Write-LearningLog "âš–ï¸ PondÃ©rations mises Ã  jour : $(($weights | ConvertTo-Json -Compress))"
    return $weights
}

# ====================================================================
# ðŸ”¬ Tendances Ã©motionnelles sur 7 jours
# ====================================================================
function Get-AthenaLearningTrend {
    $EmotionFile = Join-Path $MemoryDir 'EmotionHistory.json'
    if (!(Test-Path $EmotionFile)) { return @{} }
    try {
        $data = Get-Content $EmotionFile -Raw | ConvertFrom-Json
        $recent = $data | Sort-Object Date -Descending | Select-Object -First 7
        $trends = @{}
        foreach ($field in @('Stress','Serenite','Fatigue','Confiance','Motivation')) {
            $avgNew = ($recent | Select-Object -ExpandProperty $field | Measure-Object -Average).Average
            $prev   = ($data | Select-Object -Skip 7 | Select-Object -First 7 | Select-Object -ExpandProperty $field | Measure-Object -Average).Average
            if ($avgNew -gt $prev) { $trends[$field] = 'hausse' }
            elseif ($avgNew -lt $prev) { $trends[$field] = 'baisse' }
            else { $trends[$field] = 'stable' }
        }
        return $trends
    } catch {
        Write-LearningLog "âŒ Erreur Get-AthenaLearningTrend : $_"
        return @{}
    }
}

# ====================================================================
# ðŸ§  Moteur principal â€“ Invoke-AthenaAutoLearning
# ====================================================================
function Invoke-AthenaAutoLearning {
    Write-Host "`nðŸ§  Lancement du cycle Auto-Learning adaptatif..." -ForegroundColor Cyan
    Write-LearningLog "=== Cycle lancÃ© $(Get-Date -Format u) ==="

    $Trends = Get-AthenaLearningTrend
    $Weights = Update-LearningWeights -Trends $Trends
    $LearningIndex = Compute-LearningIndex

    $entry = [ordered]@{
        Date = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Trends = $Trends
        Weights = $Weights
        LearningIndex = [math]::Round(($Weights.Values | Measure-Object -Average).Average * 100, 2)
    }

    $existing = @()
    if (Test-Path $HistoryFile) {
        try {
            $existing = Get-Content $HistoryFile -Raw | ConvertFrom-Json
            if ($existing -isnot [System.Collections.IEnumerable] -or $existing -is [string]) { $existing = @($existing) }
            elseif ($existing -is [System.Management.Automation.PSObject]) { $existing = @($existing) }
        } catch {
            Write-LearningLog "âš ï¸ Historique corrompu, rÃ©initialisation automatique."
            $existing = @()
        }
    }

    $existing += $entry
    $existing | ConvertTo-Json -Depth 5 | Set-Content -Path $HistoryFile -Encoding UTF8

    Write-Host "âœ… Cycle Auto-Learning terminÃ©. Index : $($entry.LearningIndex)%" -ForegroundColor Green
    Write-LearningLog "âœ… Cycle terminÃ© avec LearningIndex=$($entry.LearningIndex)%"

    # --- Notification au systÃ¨me global ---
    try { Send-AthenaLearningStatus -Index $entry.LearningIndex } catch {}
}

# ====================================================================
# ðŸ”— Notification systÃ¨me
# ====================================================================
function Send-AthenaLearningStatus {
    param([double]$Index)
    try {
        if (Get-Command -Name Update-AthenaStatus -ErrorAction SilentlyContinue) {
            Update-AthenaStatus -Module 'AutoLearning' -Status 'OK' -Score $Index
        } elseif (Get-Command -Name Send-HybridSignal -ErrorAction SilentlyContinue) {
            Send-HybridSignal -Channel 'Learning' -Payload @{ Index = $Index }
        } else {
            Write-LearningLog "â„¹ï¸ Aucun canal de notification dÃ©tectÃ©."
        }
    } catch {
        Write-LearningLog "âŒ Erreur de notification : $_"
    }
}

# ====================================================================
# ðŸª¶ Export rÃ©sumÃ© court
# ====================================================================
function Export-LearningSnapshot {
    param($Entry)
    $msg = "[$($Entry.Date)] LearningIndex=$($Entry.LearningIndex)% | Tendances=$($Entry.Trends.Keys -join ',')"
    Add-Content -Path $LogFile -Value $msg
}

# ====================================================================
# ðŸ—ƒï¸ Archivage automatique
# ====================================================================
function Archive-OldLearningData {
    $ArchiveDir = Join-Path $LearningDir 'Archives'
    if (!(Test-Path $ArchiveDir)) { New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null }
    try {
        $limit = (Get-Date).AddDays(-30)
        $data = Get-Content $HistoryFile -Raw | ConvertFrom-Json
        $old = $data | Where-Object { [datetime]$_.Date -lt $limit }
        if ($old.Count -gt 0) {
            $archiveFile = Join-Path $ArchiveDir ("LearningArchive_" + (Get-Date -Format 'yyyy-MM') + '.json')
            $old | ConvertTo-Json -Depth 5 | Set-Content -Path $archiveFile -Encoding UTF8
            $new = $data | Where-Object { [datetime]$_.Date -ge $limit }
            $new | ConvertTo-Json -Depth 5 | Set-Content -Path $HistoryFile -Encoding UTF8
            Write-LearningLog "ðŸ“¦ Archivage effectuÃ© : $($old.Count) entrÃ©es dÃ©placÃ©es."
        }
    } catch { Write-LearningLog "âš ï¸ Erreur archivage : $_" }
}

# ====================================================================
# ðŸ§ª Test complet du moteur
# ====================================================================
function Test-AthenaAutoLearning {
    Write-Host "`nðŸ§ª Test du moteur Auto-Learning..." -ForegroundColor Yellow
    Invoke-AthenaAutoLearning
    $idx = Compute-LearningIndex
    Write-Host "RÃ©sultat du test : LearningIndex=$idx%" -ForegroundColor Green
}

# ====================================================================
# ðŸ”’ VÃ©rification dâ€™intÃ©gritÃ© pour AutoDeploy
# ====================================================================
function Get-AthenaModuleChecksum {
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.IO.File]::ReadAllBytes($MyInvocation.MyCommand.Path)
        ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
    } catch { "0" }
}

# ====================================================================
# ðŸ”® Hooks Phases 35â€“37
# ====================================================================
#region Phase35_SelfBuilder
# Placeholder : gÃ©nÃ©ration automatique de nouvelles rÃ¨gles via moteur GPT local
#endregion

#region Phase36_HybridSync
# Placeholder : synchronisation des donnÃ©es dâ€™apprentissage entre instances Athena
#endregion

#region Phase37_SelfEvolution
# Placeholder : adaptation dynamique du moteur cognitif selon performance systÃ¨me
#endregion

# ====================================================================
# ðŸš€ Exportation des fonctions
# ====================================================================
Export-ModuleMember -Function `
    Invoke-AthenaAutoLearning, Test-AthenaAutoLearning, Compute-LearningIndex, `
    Update-LearningWeights, Get-AthenaLearningTrend, Export-LearningSnapshot, `
    Archive-OldLearningData, Send-AthenaLearningStatus, Get-AthenaModuleChecksum

Write-Host "âœ… Module Athena.AutoLearning.psm1 (v3.2-IntegratedCore-FutureReady) chargÃ© avec succÃ¨s." -ForegroundColor Cyan
# ====================================================================


