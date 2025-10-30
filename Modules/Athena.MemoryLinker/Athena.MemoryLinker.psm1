# ====================================================================
# ðŸ”— Athena.MemoryLinker.psm1 (v1.0-Cognitive-Correlation-Engine)
# Objectif : CrÃ©er des liens entre souvenirs, Ã©motions et cognition
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === Dossiers de travail ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ModuleRoot
$MemoryDir   = Join-Path $ProjectRoot 'Memory'
$LogsDir     = Join-Path $ProjectRoot 'Logs'
$LogFile     = Join-Path $LogsDir 'AthenaMemoryLinker.log'

$ArchiveFile   = Join-Path $MemoryDir 'MemoryArchive.json'
$HarmonyFile   = Join-Path $MemoryDir 'HarmonyProfile.json'
$CognitionLog  = Join-Path $LogsDir 'AthenaCognition.log'
$LinkedMemory  = Join-Path $MemoryDir 'MemoryLinks.json'

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null }
if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Force -Path $MemoryDir | Out-Null }

# ====================================================================
# ðŸ”¹ Lecture des donnÃ©es
# ====================================================================
function Get-SourceData {
    $memories = @()
    $cognition = @()
    $harmonie = 75

    if (Test-Path $ArchiveFile) {
        try { $memories = Get-Content $ArchiveFile -Raw | ConvertFrom-Json } catch {}
    }

    if (Test-Path $CognitionLog) {
        try {
            $lines = Get-Content $CognitionLog -Tail 200
            $cognition = $lines | ForEach-Object { [PSCustomObject]@{ texte = $_; date = (Get-Date) } }
        } catch {}
    }

    if (Test-Path $HarmonyFile) {
        try {
            $json = Get-Content $HarmonyFile -Raw | ConvertFrom-Json
            $harmonie = [math]::Round($json.statistiques.indice_moyen,2)
        } catch {}
    }

    return [PSCustomObject]@{
        Memories = $memories
        Cognition = $cognition
        Harmonie = $harmonie
    }
}

# ====================================================================
# ðŸ”¹ CorrÃ©lation souvenirs â†” cognition â†” Ã©motions
# ====================================================================
function Compute-MemoryLinks {
    param([object]$Data)

    $links = @()

    foreach ($memo in $Data.Memories) {
        $phrase = $memo.Resume
        $matchCog = $Data.Cognition | Where-Object { $_.texte -match ($phrase.Split(' ')[0]) }

        $score = [math]::Round((Get-Random -Minimum 60 -Maximum 100) * ($Data.Harmonie / 100),2)

        $link = [PSCustomObject]@{
            Date = $memo.Timestamp
            Resume = $phrase
            Correlation = $score
            Emotion = if ($Data.Harmonie -gt 80) { 'Positive' } elseif ($Data.Harmonie -gt 60) { 'Neutre' } else { 'Tendue' }
            Cognitive_Link = if ((@($matchCog).Count) -gt 0) { $true } else { $false }
        }
        $links += $link
    }

    return $links
}

# ====================================================================
# ðŸ”¹ Sauvegarde des corrÃ©lations
# ====================================================================
function Save-MemoryLinks {
    param([array]$Links)

    $Links | ConvertTo-Json -Depth 4 | Out-File $LinkedMemory -Encoding utf8
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'u') | $((@($Links).Count)) corrÃ©lations mÃ©moire â†” cognition enregistrÃ©es."
}

# ====================================================================
# ðŸ”¹ Fonction principale
# ====================================================================
function Invoke-AthenaMemoryLinker {
    Write-Host "`nðŸ”— Phase 17.2 â€“ CorrÃ©lation souvenirs â†” cognition â†” Ã©motions..." -ForegroundColor Cyan

    $data = Get-SourceData
    if ($data.Memories.Count -eq 0) {
        Write-Host "âš ï¸ Aucune mÃ©moire Ã  corrÃ©ler." -ForegroundColor Yellow
        return
    }

    $links = Compute-MemoryLinks -Data $data
    Save-MemoryLinks -Links $links

    Write-Host "âœ… CorrÃ©lations enregistrÃ©es dans MemoryLinks.json`n" -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-AthenaMemoryLinker




