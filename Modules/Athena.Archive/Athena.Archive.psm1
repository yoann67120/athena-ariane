# ====================================================================
# ðŸ—„ï¸ Athena.Archive.psm1
# Phase 9 â€“ Archivage automatique des rapports et logs Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleRoot
$LogsDir     = Join-Path $RootDir "Logs"
$MemoryDir   = Join-Path $RootDir "Memory"
$HistoryDir  = Join-Path $MemoryDir "History"

# CrÃ©e le dossier History sâ€™il nâ€™existe pas
if (!(Test-Path $HistoryDir)) {
    New-Item -ItemType Directory -Path $HistoryDir -Force | Out-Null
}

$Today      = (Get-Date).ToString("yyyy-MM-dd")
$ArchiveDir = Join-Path $HistoryDir $Today
if (!(Test-Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
}

$LogFile = Join-Path $LogsDir "AthenaArchive.log"

function Write-AthenaArchiveLog {
    param([string]$Msg, [string]$Level = "INFO")
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$time][$Level] $Msg"
}

function Invoke-AthenaArchive {
    Write-Host "`nðŸ—„ï¸ Archivage automatique des rapports Athena..." -ForegroundColor Cyan
    Write-AthenaArchiveLog "DÃ©marrage de l'archivage du jour."

    # Liste des fichiers Ã  archiver
    $filesToArchive = @(
        "AthenaReport.log",
        "AthenaActions.log",
        "AthenaSupervisor.log"
    )

    foreach ($file in $filesToArchive) {
        $src = Join-Path $LogsDir $file
        if (Test-Path $src) {
            $dest = Join-Path $ArchiveDir $file
            Copy-Item -Path $src -Destination $dest -Force
            Write-AthenaArchiveLog "Fichier archivÃ© : $file"
        } else {
            Write-AthenaArchiveLog "Fichier manquant : $file" "WARN"
        }
    }

    # CrÃ©er un rÃ©sumÃ© JSON du jour
    $summary = @{
        Date   = $Today
        Score  = $null
        Status = "ok"
        Files  = @()
    }

    $reportPath = Join-Path $LogsDir "AthenaReport.log"
    if (Test-Path $reportPath) {
        $content = Get-Content $reportPath -Raw
        if ($content -match "Score global : (\d+)%") {
            $summary.Score = [int]$matches[1]
        }
        $summary.Files += "AthenaReport.log"
    }

    foreach ($f in $filesToArchive) {
        if (Test-Path (Join-Path $ArchiveDir $f)) {
            $summary.Files += $f
        }
    }

    $jsonFile = Join-Path $ArchiveDir "summary.json"
    $summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonFile -Encoding UTF8

    Write-AthenaArchiveLog "RÃ©sumÃ© journalier sauvegardÃ© : $jsonFile"
    Write-Host "âœ… Archivage du jour terminÃ© : $ArchiveDir" -ForegroundColor Green
}
Export-ModuleMember -Function Invoke-AthenaArchive




