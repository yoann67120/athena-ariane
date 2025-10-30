# ====================================================================
# ðŸª¶ Athena.MemorySync.psm1 â€“ Synchronisation mÃ©moire Ã©motionnelle
# Version : v1.1-Emotional-Continuum-Fix
# ====================================================================
# Objectif :
#   - Enregistrer humeur + rÃ©gulation dans Memory\EmotionHistory.json
#   - Corrige erreur op_Addition + renforce fiabilitÃ© JSON
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleDir
$MemoryDir   = Join-Path $RootDir "Memory"
$LogsDir     = Join-Path $RootDir "Logs"
$EmotionFile = Join-Path $MemoryDir "EmotionHistory.json"
$LogFile     = Join-Path $LogsDir "AthenaMemorySync.log"

if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null }
if (!(Test-Path $LogsDir))   { New-Item -ItemType Directory -Path $LogsDir   -Force | Out-Null }

function Write-MemorySyncLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t] $Msg"
}

# --------------------------------------------------------------------
# ðŸ“¥ Lecture de lâ€™humeur et de la derniÃ¨re rÃ©gulation
# --------------------------------------------------------------------
function Get-AthenaCurrentEmotionData {
    $mood  = "inconnue"
    $adjust= "aucune"
    try {
        if (Get-Command Get-AthenaState -ErrorAction SilentlyContinue) {
            $mood = Get-AthenaState
        } elseif (Get-Command Get-AthenaEmotion -ErrorAction SilentlyContinue) {
            $mood = Get-AthenaEmotion
        }

        $lastReg = (Get-Content (Join-Path $LogsDir "AthenaSelfRegulation.log") -ErrorAction SilentlyContinue | Select-Object -Last 1)
        if ($lastReg -match "Ajustement\s*:\s*(.+)$") { $adjust = $Matches[1] }
    } catch {
        Write-MemorySyncLog "Erreur rÃ©cupÃ©ration donnÃ©es Ã©motionnelles : $_"
    }

    return @{
        Date   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Humeur = $mood
        Reg    = $adjust
    }
}

# --------------------------------------------------------------------
# ðŸ’¾ Enregistrement dans la mÃ©moire persistante
# --------------------------------------------------------------------
function Invoke-AthenaMemorySync {
    Write-Host "`nðŸª¶ Synchronisation de la mÃ©moire Ã©motionnelle..." -ForegroundColor Cyan
    $entry = Get-AthenaCurrentEmotionData

    # Charger ou initialiser l'historique
    $history = @()
    if (Test-Path $EmotionFile) {
        try {
            $raw = Get-Content $EmotionFile -Raw
            if ($raw.Trim() -ne "") {
                $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
                if ($parsed -is [System.Collections.IEnumerable]) {
                    $history = @($parsed)
                } else {
                    $history = @($parsed)
                }
            }
        } catch {
            Write-MemorySyncLog "Erreur lecture JSON : $_"
            $history = @()
        }
    }

    # Forcer en tableau et ajouter l'entrÃ©e
    if ($history -isnot [System.Collections.ArrayList]) { $history = @($history) }
    $history += ,$entry

    # Sauvegarde
    try {
        $json = $history | ConvertTo-Json -Depth 5
        Set-Content -Path $EmotionFile -Value $json -Encoding UTF8
        Write-MemorySyncLog "Enregistrement : Humeur=$($entry.Humeur) | Reg=$($entry.Reg)"
        Write-Host "ðŸ’¾ Emotion enregistrÃ©e : $($entry.Humeur) | RÃ©gulation : $($entry.Reg)" -ForegroundColor Green
    } catch {
        Write-Warning "âš ï¸ Erreur dâ€™Ã©criture mÃ©moire : $_"
        Write-MemorySyncLog "Erreur Ã©criture : $_"
    }

    # Diagnostic final
    if (Test-Path $EmotionFile) {
        $count = (Get-Content $EmotionFile | Measure-Object -Line).Lines
        Write-Host "ðŸ§  Historique Ã©motionnel mis Ã  jour ($count lignes)." -ForegroundColor Yellow
    }
    Write-Host "âœ… MÃ©moire Ã©motionnelle synchronisÃ©e." -ForegroundColor Cyan
}

Export-ModuleMember -Function Invoke-AthenaMemorySync, Get-AthenaCurrentEmotionData
Write-Host "ðŸª¶ Module Athena.MemorySync.psm1 chargÃ© (v1.1-Emotional-Continuum-Fix)." -ForegroundColor Magenta
Write-MemorySyncLog "Module chargÃ© (v1.1-Emotional-Continuum-Fix)."




