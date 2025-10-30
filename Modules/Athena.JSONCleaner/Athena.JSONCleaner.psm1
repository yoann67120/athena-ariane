# ====================================================================
# ðŸ§¹ Athena.JSONCleaner.psm1 â€“ v1.0-SecureAuto
# Objectif : Analyse, validation et rÃ©paration automatique des fichiers JSON
# Auteur : Ariane V4 / Athena Engine
# Phase 28 â€“ JSONCleaner & Data Sanitizer
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Initialisation des chemins ===
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ConfigDir  = Join-Path $RootDir "Config"
$CorruptedDir = Join-Path $LogsDir "Corrupted"

foreach ($dir in @($LogsDir, $MemoryDir, $CorruptedDir)) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

$ReportFile = Join-Path $LogsDir "JSONCleaner_Report.json"
$LogFile    = Join-Path $LogsDir "AutoJSONClean.log"
$MemoryFile = Join-Path $MemoryDir "JSONCleaner.Memory.json"
$SettingsFile = Join-Path $ConfigDir "jsoncleaner.settings.json"

# === Configuration par dÃ©faut ===
if (!(Test-Path $SettingsFile)) {
    $DefaultConfig = @{ FullAuto = $false; StabilityThreshold = 3 }
    $DefaultConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath $SettingsFile -Encoding UTF8
}

# ====================================================================
# ðŸ“’ Fonction de log
# ====================================================================
function Write-JSONCleanerLog {
    param([string]$Message,[string]$Level="INFO")
    $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Message"
}

# ====================================================================
# ðŸ” Liste tous les fichiers JSON valides Ã  analyser
# ====================================================================
function Get-AthenaJSONFiles {
    [CmdletBinding()]
    param()
    $dirs = @("$MemoryDir","$LogsDir")
    $files = @()
    foreach ($d in $dirs) {
        $files += Get-ChildItem -Path $d -Filter *.json -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '\.bak|\.old|\.log' }
    }
    return $files
}

# ====================================================================
# âœ… VÃ©rifie la validitÃ© dâ€™un fichier JSON
# ====================================================================
function Test-AthenaJSONValid {
    param([string]$FilePath)
    try {
        Get-Content -Path $FilePath -Raw | ConvertFrom-Json | Out-Null
        return $true
    } catch {
        return $false
    }
}

# ====================================================================
# ðŸ§  Tentative de rÃ©paration lÃ©gÃ¨re dâ€™un fichier JSON
# ====================================================================
function Repair-AthenaJSON {
    param([string]$FilePath)
    $text = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $text) { return "Empty" }

    # Ã‰tape 1 : Normalisation des guillemets typographiques
    $text = $text -replace '[â€œâ€]', '"' -replace "[â€˜â€™]", "'"

    # Ã‰tape 2 : Suppression des caractÃ¨res parasites avant/aprÃ¨s
    $text = $text -replace '^[^\{\[]+','' -replace '[^\}\]]+$',''

    # Ã‰tape 3 : VÃ©rifie si le JSON est valide maintenant
    try {
        $obj = $text | ConvertFrom-Json -ErrorAction Stop
        # Sauvegarde prÃ©alable
        $bak = "$FilePath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path $FilePath -Destination $bak -Force
        # RÃ©Ã©criture propre en UTF8
        $obj | ConvertTo-Json -Depth 6 | Out-File -FilePath $FilePath -Encoding UTF8
        Write-JSONCleanerLog "Fichier rÃ©parÃ© : $FilePath"
        return "Fixed"
    } catch {
        Write-JSONCleanerLog "Ã‰chec de rÃ©paration : $FilePath" "WARN"
        return "Failed"
    }
}

# ====================================================================
# ðŸ§± DÃ©place un fichier corrompu dans Logs\Corrupted
# ====================================================================
function Move-ToCorrupted {
    param([string]$FilePath)
    $dest = Join-Path $CorruptedDir (Split-Path $FilePath -Leaf)
    Move-Item -Path $FilePath -Destination $dest -Force -ErrorAction SilentlyContinue
    Write-JSONCleanerLog "DÃ©placÃ© vers Corrupted : $FilePath"
}

# ====================================================================
# ðŸ”’ VÃ©rifie si un fichier est protÃ©gÃ© (ne pas modifier)
# ====================================================================
function Is-FileProtected {
    param([string]$FilePath)
    $protectedTokens = @("schema","phase","config")
    foreach ($tok in $protectedTokens) {
        if ($FilePath -match $tok) { return $true }
    }
    return $false
}

# ====================================================================
# ðŸ“Š Fonction principale â€“ Invoke-AthenaJSONCleaner
# ====================================================================
function Invoke-AthenaJSONCleaner {
    [CmdletBinding()]
    param()
    Write-Host "`nðŸ§¹ DÃ©marrage du nettoyage JSON..." -ForegroundColor Cyan
    Write-JSONCleanerLog "=== Lancement du cycle JSONCleaner ==="

    $files = Get-AthenaJSONFiles
    $total = $files.Count
    $fixed = 0; $moved = 0; $skipped = 0

    foreach ($f in $files) {
        if (Is-FileProtected $f.FullName) {
            $skipped++
            continue
        }

        if (Test-AthenaJSONValid $f.FullName) {
            continue
        } else {
            $result = Repair-AthenaJSON $f.FullName
            if ($result -eq "Fixed") { $fixed++ }
            elseif ($result -eq "Failed") {
                Move-ToCorrupted $f.FullName
                $moved++
            }
        }
    }

    # --- Rapport JSON ---
    $summary = [ordered]@{
        Date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        TotalFiles = $total
        Fixed = $fixed
        MovedToCorrupted = $moved
        Skipped = $skipped
    }
    $summary | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportFile -Encoding UTF8

    Write-Host "âœ… Nettoyage terminÃ© : $fixed rÃ©parÃ©s, $moved dÃ©placÃ©s, $skipped ignorÃ©s." -ForegroundColor Green
    Write-JSONCleanerLog "Fin du cycle : $fixed fixed, $moved moved, $skipped skipped"

    # --- MÃ©morisation de la stabilitÃ© ---
    Evaluate-JSONCleanerStability -Fixed $fixed -Moved $moved
}

# ====================================================================
# ðŸ“ˆ Ã‰valuation de la stabilitÃ© des cycles JSONCleaner
# ====================================================================
function Evaluate-JSONCleanerStability {
    param([int]$Fixed,[int]$Moved)
    $memory = @()
    if (Test-Path $MemoryFile) {
        try { $memory = Get-Content $MemoryFile -Raw | ConvertFrom-Json } catch { $memory=@() }
    }

    $memory += [ordered]@{
        Date = (Get-Date).ToString("yyyy-MM-dd")
        Fixed = $Fixed
        Moved = $Moved
    }

    # garde les 3 derniers cycles
    if ($memory.Count -gt 3) { $memory = $memory[-3..-1] }

    $memory | ConvertTo-Json -Depth 3 | Out-File -FilePath $MemoryFile -Encoding UTF8

    $stableCycles = ($memory | Where-Object { $_.Fixed -eq 0 -and $_.Moved -eq 0 }).Count
    if ($stableCycles -ge 3) {
        Suggest-FullAutoUpgrade
    }
}

# ====================================================================
# ðŸ§  Suggestion automatique de passage en mode FullAuto
# ====================================================================
function Suggest-FullAutoUpgrade {
    try {
        $config = Get-Content $SettingsFile -Raw | ConvertFrom-Json
    } catch {
        $config = @{ FullAuto = $false; StabilityThreshold = 3 }
    }

    if ($Global:AthenaSecurityLevel -ge 3) {
        $config.FullAuto = $true
        $config | ConvertTo-Json -Depth 3 | Out-File -FilePath $SettingsFile -Encoding UTF8
        Write-JSONCleanerLog "Activation automatique du mode FullAuto (niveau sÃ©curitÃ© â‰¥3)"
        Write-Host "ðŸ§  Mode FullAuto activÃ© automatiquement." -ForegroundColor Green
    } else {
        Write-Host "ðŸ’¡ Suggestion : Tous les fichiers sont stables depuis 3 cycles." -ForegroundColor Cyan
        Write-Host "   Souhaitez-vous activer le mode FullAuto ? (modifiez Config\jsoncleaner.settings.json)" -ForegroundColor Gray
        Write-JSONCleanerLog "Suggestion : passage en FullAuto recommandÃ©."
    }
}

Export-ModuleMember -Function Invoke-AthenaJSONCleaner
Write-Host "ðŸ§© Module Athena.JSONCleaner chargÃ© (v1.0-SecureAuto)." -ForegroundColor Cyan



