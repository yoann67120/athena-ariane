# ====================================================================
# ðŸ“ˆ Athena.History.psm1
# Phase 9 â€“ Consolidation des performances et mÃ©moire historique
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleRoot
$MemoryDir   = Join-Path $RootDir "Memory"
$HistoryDir  = Join-Path $MemoryDir "History"
$LogsDir     = Join-Path $RootDir "Logs"

$HistoryFile = Join-Path $MemoryDir "AthenaHistory.json"
$LogFile     = Join-Path $LogsDir "AthenaHistory.log"

function Write-AthenaHistoryLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

function Invoke-AthenaHistory {
    Write-Host "`nðŸ“ˆ Consolidation de lâ€™historique Athena..." -ForegroundColor Cyan
    Write-AthenaHistoryLog "DÃ©but de la consolidation."

    if (!(Test-Path $HistoryDir)) {
        Write-Host "âš ï¸ Aucun dossier dâ€™historique trouvÃ© ($HistoryDir)." -ForegroundColor Yellow
        Write-AthenaHistoryLog "Dossier History introuvable." "WARN"
        return
    }

    # Lecture de tous les rÃ©sumÃ©s journaliers
    $summaries = @()
    Get-ChildItem $HistoryDir -Directory | ForEach-Object {
        $summaryFile = Join-Path $_.FullName "summary.json"
        if (Test-Path $summaryFile) {
            try {
                $data = Get-Content $summaryFile -Raw | ConvertFrom-Json
                $summaries += [PSCustomObject]@{
                    Date  = $data.Date
                    Score = $data.Score
                    Status = $data.Status
                }
            } catch {
                Write-AthenaHistoryLog "Erreur lecture $summaryFile : $_" "WARN"
            }
        }
    }

    if (@($summaries).Count -eq 0) {
        Write-Host "âš ï¸ Aucun rÃ©sumÃ© trouvÃ© pour gÃ©nÃ©rer lâ€™historique." -ForegroundColor Yellow
        return
    }

    # Tri chronologique
    $summaries = $summaries | Sort-Object Date

    # Calcul des moyennes et tendance
    $scores = $summaries | Where-Object { $_.Score } | Select-Object -ExpandProperty Score
    $avg7   = if ((@($scores).Count) -ge 7) { [math]::Round(($scores | Select-Object -Last 7 | Measure-Object -Average).Average,2) } else { [math]::Round(($scores | Measure-Object -Average).Average,2) }
    $trend  = "stable"
    if ((@($scores).Count) -gt 1) {
        $diff = $scores[-1] - $scores[-2]
        if ($diff -gt 0) { $trend = "hausse" }
        elseif ($diff -lt 0) { $trend = "baisse" }
    }

    $history = @{
        LastUpdate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Average7d  = $avg7
        Trend      = $trend
        Entries    = $summaries
    }

    $history | ConvertTo-Json -Depth 6 | Out-File -FilePath $HistoryFile -Encoding UTF8
    Write-AthenaHistoryLog "Historique consolidÃ© : $HistoryFile (Moyenne=$avg7 / Tendance=$trend)"
    Write-Host "âœ… Historique mis Ã  jour ($(@($summaries).Count) entrÃ©es, moyenne $avg7%, tendance $trend)" -ForegroundColor Green
}
Export-ModuleMember -Function Invoke-AthenaHistory




