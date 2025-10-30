# ====================================================================
# ðŸŒ¿ Athena.AutoHarmony.psm1 â€“ Moteur dâ€™homÃ©ostasie Ã©motionnelle
# Version : v1.5-Core-HarmonyFusion
# Auteur  : Athena Core Engine / Ariane V4
# ====================================================================
# Objectif :
#   - Calculer lâ€™indice global dâ€™harmonie cognitive et Ã©motionnelle
#   - DÃ©tecter anomalies et stress (SafeOps, Persona, Cognition)
#   - Ajuster dynamiquement les seuils internes (mode DryRun par dÃ©faut)
#   - Journaliser et apprendre les tendances dâ€™Ã©quilibre
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleDir
$MemoryDir   = Join-Path $RootDir "Memory"
$LogsDir     = Join-Path $RootDir "Logs"

$EmotionFile   = Join-Path $MemoryDir "EmotionHistory.json"
$HarmonyFile   = Join-Path $MemoryDir "HarmonyProfile.json"
$RulesFile     = Join-Path $MemoryDir "AutoHarmonyRules.json"
$BalanceFile   = Join-Path $MemoryDir "EmotionalBalance.json"
$LogFile       = Join-Path $LogsDir  "AthenaHarmony.log"

foreach ($p in @($MemoryDir,$LogsDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# ====================================================================
# ðŸ”¹ UTILITAIRES DE LOG ET DE SAUVEGARDE
# ====================================================================
function Write-HarmonyLog {
    param([string]$Message,[string]$Level="INFO")
    $ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$ts][$Level] $Message"
}

function Create-HarmonySnapshot {
    param([string]$Target)
    if (Test-Path $Target) {
        $bak = "$Target.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
        Copy-Item $Target $bak -Force
        Write-HarmonyLog "Snapshot crÃ©Ã© : $bak"
    }
}

# ====================================================================
# ðŸ”¹ Lecture de lâ€™historique Ã©motionnel
# ====================================================================
function Get-EmotionHistory {
    if (!(Test-Path $EmotionFile)) { return @() }
    try {
        $data = Get-Content $EmotionFile -Raw | ConvertFrom-Json
        if ($null -eq $data) { return @() }
        return @($data)
    } catch {
        Write-Warning "âš ï¸ Erreur de lecture EmotionHistory.json : $_"
        Write-HarmonyLog "Erreur lecture EmotionHistory.json : $_"
        return @()
    }
}

# ====================================================================
# ðŸ”¹ Collecte Ã©largie de lâ€™Ã©tat systÃ¨me et cognitif
# ====================================================================
function Collect-HarmonyInputs {
    Write-HarmonyLog "Collecte des Ã©tats cognitifs et Ã©motionnels..."
    $inputs = [ordered]@{
        Timestamp  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        CPU        = 0
        RAM_FreeMB = 0
        Errors     = 0
        Emotion    = "neutre"
        Stress     = 0
    }

    try {
        $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $mem = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB,2)
        $inputs.CPU = [math]::Round($cpu,1)
        $inputs.RAM_FreeMB = $mem
    } catch {
        Write-HarmonyLog "Erreur collecte CPU/RAM : $_"
    }

    # Comptage dâ€™erreurs rÃ©centes SafeOps / Logs
    try {
        $safeLog = Join-Path $LogsDir "SafeOps.log"
        if (Test-Path $safeLog) {
            $err = (Get-Content $safeLog -Tail 50 | Select-String "Erreur|Error|Critical").Count
            $inputs.Errors = $err
        }
    } catch {
        Write-HarmonyLog "Erreur lecture SafeOps.log : $_"
    }

    # Lecture Ã©motion dominante
    try {
        $emo = Get-EmotionHistory | Select-Object -Last 1
        if ($emo -and $emo.mood) { $inputs.Emotion = $emo.mood }
    } catch {}

    # DÃ©finition dâ€™un niveau de stress brut
    try {
        $inputs.Stress = [math]::Min(([math]::Round(($inputs.CPU/2)+($inputs.Errors*5))),100)
    } catch { $inputs.Stress = 0 }

    Write-HarmonyLog "Collecte terminÃ©e : CPU=$($inputs.CPU)% | RAM=$($inputs.RAM_FreeMB)MB | Err=$($inputs.Errors) | Emo=$($inputs.Emotion) | Stress=$($inputs.Stress)"
    return $inputs
}

# ====================================================================
# ðŸ”¹ Calcul de lâ€™indice dâ€™harmonie global
# ====================================================================
function Compute-HarmonyIndex {
    param([hashtable]$Inputs)

    $emotionWeight = switch -regex ($Inputs.Emotion) {
        "colÃ¨re|critique|inquiÃ¨te" { 0.6 }
        "fatiguÃ©|Ã©puisÃ©"           { 0.7 }
        "heureux|calme|neutre"     { 1.0 }
        default                    { 0.8 }
    }

    $base   = 100 - (($Inputs.CPU/2) + ($Inputs.Errors*3) + ($Inputs.Stress/3))
    $indice = [math]::Round(($base * $emotionWeight),2)
    $indice = [math]::Min([math]::Max($indice,0),100)

    Write-HarmonyLog "Indice calculÃ© : $indice (poids Ã©motion=$emotionWeight)"
    return [PSCustomObject]@{
        Timestamp  = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Emotion    = $Inputs.Emotion
        CPU        = $Inputs.CPU
        RAM_FreeMB = $Inputs.RAM_FreeMB
        Errors     = $Inputs.Errors
        Stress     = $Inputs.Stress
        Indice     = $indice
    }
}

# ====================================================================
# ðŸ”¹ Ajustement dynamique (DryRun par dÃ©faut)
# ====================================================================
function Adjust-HarmonyParameters {
    param([object]$Stats,[switch]$ApplyChange)

    $thresholds = @{
        SafeOps_CPU_Max = 85
        Stress_Limit    = 70
        Recovery_Mode   = $false
    }

    if ($Stats.Indice -lt 60) {
        $thresholds.Recovery_Mode = $true
        $thresholds.SafeOps_CPU_Max = 70
        $thresholds.Stress_Limit = 50
        Write-Host "âš ï¸ Mode rÃ©cupÃ©ration activÃ© : rÃ©duction des seuils." -ForegroundColor Yellow
    }

    if ($ApplyChange) {
        try {
            Create-HarmonySnapshot -Target $RulesFile
            $thresholds | ConvertTo-Json -Depth 3 | Set-Content -Path $RulesFile -Encoding UTF8
            Write-HarmonyLog "Seuils ajustÃ©s et sauvegardÃ©s."
        } catch {
            Write-Warning "âŒ Impossible dâ€™ajuster les seuils : $_"
        }
    } else {
        Write-Host "ðŸ”Ž Mode DryRun : aucun changement appliquÃ© (prÃ©visualisation)" -ForegroundColor DarkGray
        Write-HarmonyLog "Ajustement simulÃ© (DryRun)."
    }
}

# ====================================================================
# ðŸ”¹ Ã‰tat & Feedback Cockpit
# ====================================================================
function Show-HarmonyFeedback {
    param([object]$Stats)
    if ($Stats.Indice -ge 80) { $etat='SÃ©rÃ©nitÃ©';$couleur='Green' }
    elseif ($Stats.Indice -ge 60) { $etat='Ã‰quilibre';$couleur='Cyan' }
    elseif ($Stats.Indice -ge 40) { $etat='Alerte';$couleur='Yellow' }
    else { $etat='Stress';$couleur='Red' }

    Write-Host "âš–ï¸ Ã‰tat actuel : $etat (Indice $($Stats.Indice)%)" -ForegroundColor $couleur

    foreach ($cmd in 'Invoke-AthenaEmotion','Invoke-AthenaSound','Invoke-CockpitSignal') {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            try { Start-Job { & $using:cmd -Mood $using:etat } | Out-Null } catch {}
        }
    }
    return $etat
}

# ====================================================================
# ðŸ”¹ Journalisation et apprentissage de base
# ====================================================================
function Update-HarmonyLogs {
    param([object]$Stats,[string]$Etat)

    $entry = [PSCustomObject]@{
        Timestamp = $Stats.Timestamp
        Etat      = $Etat
        Indice    = $Stats.Indice
        CPU       = $Stats.CPU
        RAM       = $Stats.RAM_FreeMB
        Emotion   = $Stats.Emotion
        Stress    = $Stats.Stress
    }

    $history = @()
    if (Test-Path $HarmonyFile) {
        try { $history = Get-Content $HarmonyFile -Raw | ConvertFrom-Json } catch {}
    }

   if (-not $history) {
    $history = @()
}
if ($history -isnot [System.Collections.IEnumerable] -or $history -is [string]) {
    $history = @($history)
}
$history += $entry

    $history | ConvertTo-Json -Depth 4 | Out-File $HarmonyFile -Encoding utf8
    Add-Content -Path $LogFile -Value "[$($entry.Timestamp)] Ã‰tat=$Etat | Indice=$($Stats.Indice)% | CPU=$($Stats.CPU)% | Stress=$($Stats.Stress)%"
    Write-HarmonyLog "EntrÃ©e enregistrÃ©e pour $Etat ($($Stats.Indice)%)"
}

# ====================================================================
# ðŸ”¹ Fonction principale
# ====================================================================
function Invoke-AthenaHarmony {
    Write-Host "`nðŸ’« DÃ©marrage du cycle Auto-Harmony (v1.5-Core)..." -ForegroundColor Yellow
    Write-HarmonyLog "Cycle Auto-Harmony lancÃ©."

    $inputs = Collect-HarmonyInputs
    $stats  = Compute-HarmonyIndex -Inputs $inputs
    $etat   = Show-HarmonyFeedback -Stats $stats
    Update-HarmonyLogs -Stats $stats -Etat $etat
    Adjust-HarmonyParameters -Stats $stats  # DryRun par dÃ©faut

    Write-Host "âœ… Cycle Auto-Harmony complÃ©tÃ© avec succÃ¨s.`n" -ForegroundColor Green
    Write-HarmonyLog "Cycle complÃ©tÃ© â€“ Ã©tat $etat (indice $($stats.Indice)%)"
}

if (-not (Get-Command Invoke-AthenaAutoHarmony -ErrorAction SilentlyContinue)) {
    function Invoke-AthenaAutoHarmony { Invoke-AthenaHarmony @PSBoundParameters }
}

# ====================================================================
# ðŸ”¹ Export des fonctions
# ====================================================================
Export-ModuleMember -Function `
    Invoke-AthenaHarmony, `
    Invoke-AthenaAutoHarmony, `
    Collect-HarmonyInputs, `
    Compute-HarmonyIndex, `
    Adjust-HarmonyParameters, `
    Show-HarmonyFeedback, `
    Update-HarmonyLogs



