# ====================================================================
# ðŸŒ… Athena.MemoryReport.psm1 (v1.0-Visual-Memory-Reporter)
# Objectif : GÃ©nÃ©rer un rapport visuel et synthÃ©tique des souvenirs clÃ©s dâ€™Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === Dossiers de travail ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ModuleRoot
$MemoryDir   = Join-Path $ProjectRoot 'Memory'
$LogsDir     = Join-Path $ProjectRoot 'Logs'
$ReportsDir  = Join-Path $ProjectRoot 'Reports'

$MemoryArchive = Join-Path $MemoryDir 'MemoryArchive.json'
$MemoryLinks   = Join-Path $MemoryDir 'MemoryLinks.json'
$HarmonyFile   = Join-Path $MemoryDir 'HarmonyProfile.json'
$ReportFile    = Join-Path $ReportsDir 'AthenaMemoryReport.txt'

if (!(Test-Path $ReportsDir)) { New-Item -ItemType Directory -Force -Path $ReportsDir | Out-Null }

# ====================================================================
# ðŸ”¹ Lecture des donnÃ©es sources
# ====================================================================
function Get-MemoryData {
    $archive = @()
    $links   = @()
    $harmonie = 75

    if (Test-Path $MemoryArchive) {
        try { $archive = Get-Content $MemoryArchive -Raw | ConvertFrom-Json } catch {}
    }

    if (Test-Path $MemoryLinks) {
        try { $links = Get-Content $MemoryLinks -Raw | ConvertFrom-Json } catch {}
    }

    if (Test-Path $HarmonyFile) {
        try {
            $json = Get-Content $HarmonyFile -Raw | ConvertFrom-Json
            $harmonie = [math]::Round($json.statistiques.indice_moyen,2)
        } catch {}
    }

    return [PSCustomObject]@{
        Archive = $archive
        Links = $links
        Harmonie = $harmonie
    }
}

# ====================================================================
# ðŸ”¹ GÃ©nÃ©ration du rapport visuel
# ====================================================================
function Generate-MemoryReport {
    param([object]$Data)

    $line = 'â•' * 60
    $report = @()
    $report += "ATHENA â€“ RAPPORT MÃ‰MOIRE VISUEL (Phase 17.3)"
    $report += $line
    $report += "ðŸ§  Indice d'Harmonie moyen : $($Data.Harmonie)%"
    $report += "ðŸ“š Nombre de souvenirs archivÃ©s : $($Data.Archive.Count)"
    $report += "ðŸ”— CorrÃ©lations cognitives : $($Data.Links.Count)"
    $report += $line

    if ($Data.Links.Count -gt 0) {
        $topLinks = $Data.Links | Sort-Object -Property Correlation -Descending | Select-Object -First 5
        $report += "âœ¨ TOP 5 CORRÃ‰LATIONS :"
        foreach ($link in $topLinks) {
            $report += "[$($link.Date)] ($($link.Emotion)) â€“ CorrÃ©lation : $($link.Correlation)%"
            $report += "â†’ $($link.Resume)"
            $report += ''
        }
    }

    if ($Data.Archive.Count -gt 0) {
        $lastMem = $Data.Archive | Select-Object -Last 3
        $report += $line
        $report += "ðŸª¶ DERNIERS SOUVENIRS SYNTHÃ‰TISÃ‰S :"
        foreach ($mem in $lastMem) {
            $report += "[$($mem.Timestamp)] Poids : $($mem.Poids) â†’ $($mem.Resume.Substring(0, [math]::Min(120,$mem.Resume.Length)))..."
        }
    }

    $report += $line
    $report += "ðŸ“… Rapport gÃ©nÃ©rÃ© le : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report -join "`n" | Out-File $ReportFile -Encoding utf8

    Write-Host "ðŸ“„ Rapport mÃ©moire gÃ©nÃ©rÃ© : $ReportFile" -ForegroundColor Green
}

# ====================================================================
# ðŸ”¹ Fonction principale
# ====================================================================
function Invoke-AthenaMemoryReport {
    Write-Host "`nðŸŒ… Phase 17.3 â€“ GÃ©nÃ©ration du rapport visuel de mÃ©moire..." -ForegroundColor Cyan

    $data = Get-MemoryData
    if ($data.Archive.Count -eq 0) {
        Write-Host "âš ï¸ Aucune donnÃ©e mÃ©moire Ã  inclure dans le rapport." -ForegroundColor Yellow
        return
    }

    Generate-MemoryReport -Data $data

    Write-Host "âœ… Rapport de mÃ©moire visuelle complÃ©tÃ© avec succÃ¨s.`n" -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-AthenaMemoryReport




