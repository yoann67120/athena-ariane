# ====================================================================
# ðŸ§  Athena.AutoMemory.psm1 (v1.0-Adaptive-Memory-Engine)
# Objectif : SynthÃ¨se, compression et archivage des mÃ©moires dâ€™Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === Dossiers de travail ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ModuleRoot
$MemoryDir   = Join-Path $ProjectRoot 'Memory'
$LogsDir     = Join-Path $ProjectRoot 'Logs'
$ArchiveDir  = Join-Path $ProjectRoot 'Archive'
$MemoryArchive = Join-Path $MemoryDir 'MemoryArchive.json'
$MemoryIndex   = Join-Path $MemoryDir 'MemoryIndex.json'
$DailySummary  = Join-Path $MemoryDir 'DailySummary.json'
$HarmonyFile   = Join-Path $MemoryDir 'HarmonyProfile.json'
$DailyLog      = Join-Path $LogsDir 'AthenaDaily.log'

if (!(Test-Path $ArchiveDir)) { New-Item -ItemType Directory -Force -Path $ArchiveDir | Out-Null }
if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Force -Path $MemoryDir | Out-Null }

# ====================================================================
# ðŸ”¹ Lecture et extraction des donnÃ©es rÃ©centes
# ====================================================================
function Get-RecentMemories {
    $memories = @()

    if (Test-Path $DailySummary) {
        try {
            $data = Get-Content $DailySummary -Raw | ConvertFrom-Json
            if ((@($data).Count) -gt 7) { $memories = $data | Select-Object -Last 7 }
            else { $memories = $data }
        } catch {}
    }

    if ((@($memories).Count) -eq 0 -and (Test-Path $DailyLog)) {
        $raw = Get-Content $DailyLog -Tail 200
        $memories = @($raw | ForEach-Object { [PSCustomObject]@{ texte = $_; date = (Get-Date) } })
    }

    return $memories
}

# ====================================================================
# ðŸ”¹ Analyse pondÃ©rÃ©e par lâ€™harmonie Ã©motionnelle
# ====================================================================
function Compute-MemoryWeight {
    $weight = 1
    if (Test-Path $HarmonyFile) {
        try {
            $json = Get-Content $HarmonyFile -Raw | ConvertFrom-Json
            $avg = [math]::Round($json.statistiques.indice_moyen,2)
            $weight = if ($avg -gt 90) { 1.2 } elseif ($avg -gt 75) { 1 } else { 0.8 }
        } catch {}
    }
    return $weight
}

# ====================================================================
# ðŸ”¹ SynthÃ¨se des souvenirs rÃ©cents
# ====================================================================
function Summarize-Memories {
    param([array]$Data, [double]$Weight)

    $summaryText = ""
    $keywords = @()

    foreach ($item in $Data) {
        $line = ($item.texte) -replace '[^\p{L}\p{N}\s\.]',''
        if ($line.Length -gt 20) { $keywords += $line }
    }

    if ((@($keywords).Count) -gt 0) {
        $joined = ($keywords -join ' ')
        $words = ($joined.Split(' ') | Select-Object -Unique)
        $summaryText = "RÃ©sumÃ© pondÃ©rÃ© ($Weight) : " + ($words | Select-Object -First 40 -join ' ') + "..."
    } else {
        $summaryText = "Aucune donnÃ©e significative dÃ©tectÃ©e."
    }

    return $summaryText
}

# ====================================================================
# ðŸ”¹ Enregistrement de la mÃ©moire compressÃ©e
# ====================================================================
function Save-CompressedMemory {
    param([string]$Summary, [double]$Weight)

    $entry = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Poids     = $Weight
        Resume    = $Summary
    }

    $archive = @()
    if (Test-Path $MemoryArchive) {
        try { $archive = Get-Content $MemoryArchive -Raw | ConvertFrom-Json } catch {}
    }

    $archive += $entry
    $archive | ConvertTo-Json -Depth 3 | Out-File $MemoryArchive -Encoding utf8

    # Mise Ã  jour index
    $index = @()
    if (Test-Path $MemoryIndex) {
        try { $index = Get-Content $MemoryIndex -Raw | ConvertFrom-Json } catch {}
    }

    $index += [PSCustomObject]@{
        Date = (Get-Date).ToString('yyyy-MM-dd')
        Resume = $Summary.Substring(0, [math]::Min(60, $Summary.Length)) + '...'
    }
    $index | ConvertTo-Json -Depth 3 | Out-File $MemoryIndex -Encoding utf8
}

# ====================================================================
# ðŸ”¹ Nettoyage des anciennes mÃ©moires (>30 jours)
# ====================================================================
function Clean-OldMemories {
    $files = Get-ChildItem -Path $MemoryDir -Filter '*.json' -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
    if ((@($files).Count) -gt 0) {
        $dest = Join-Path $ArchiveDir 'Memory'
        if (!(Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
        foreach ($f in $files) {
            Move-Item $f.FullName -Destination $dest -Force
        }
        Write-Host "ðŸ—„ï¸ Anciennes mÃ©moires archivÃ©es : $((@($files).Count)) fichiers dÃ©placÃ©s." -ForegroundColor DarkGray
    }
}

# ====================================================================
# ðŸ”¹ Fonction principale : Invoke-AthenaAutoMemory
# ====================================================================
function Invoke-AthenaAutoMemory {
    Write-Host "`nðŸ§  Phase 17.0 â€“ SynthÃ¨se de la mÃ©moire adaptative..." -ForegroundColor Cyan

    $recent = Get-RecentMemories
    $weight = Compute-MemoryWeight

    if ((@($recent).Count) -eq 0) {
        Write-Host "âš ï¸ Aucune mÃ©moire rÃ©cente Ã  analyser." -ForegroundColor Yellow
        return
    }

    $summary = Summarize-Memories -Data $recent -Weight $weight
    Save-CompressedMemory -Summary $summary -Weight $weight
    Clean-OldMemories

    Write-Host "âœ… MÃ©moire synthÃ©tisÃ©e et compressÃ©e avec succÃ¨s.`n" -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-AthenaAutoMemory




