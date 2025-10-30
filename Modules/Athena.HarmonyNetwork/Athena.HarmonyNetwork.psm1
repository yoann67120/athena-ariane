# ====================================================================
# ðŸ§  Athena.HarmonyNetwork.psm1 â€“ v1.0-HarmonyCore-Full
# --------------------------------------------------------------------
# CrÃ©Ã© par : Yoann Rousselle / Athena Core
# Date : 2025-10-20
# --------------------------------------------------------------------
# Objectif : CrÃ©er un rÃ©seau d'harmonie interne auto-Ã©volutif reliant
# cognition, Ã©motion et perception sensorielle. Permet Ã  Athena de :
# - CorrÃ©ler Ã©motions â†” performances â†” charge systÃ¨me
# - Ajuster ses pondÃ©rations internes pour retrouver lâ€™Ã©quilibre
# - Enregistrer et archiver les Ã©tats dâ€™harmonie
# - Communiquer le score dâ€™harmonie au Cockpit
# - Servir de base pour la conscience rÃ©flexive (phase 35+)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# --- Initialisation des dossiers ---
$RootDir    = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$ModulesDir = Join-Path $RootDir 'Modules'
$MemoryDir  = Join-Path $RootDir 'Memory'
$LogsDir    = Join-Path $RootDir 'Logs'

$HarmonyState = Join-Path $MemoryDir 'HarmonyState.json'
$HarmonyLog   = Join-Path $LogsDir 'HarmonyCycle.log'

foreach ($p in @($MemoryDir, $LogsDir)) { if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null } }

# ====================================================================
# âœï¸ Fonction de log
# ====================================================================
function Write-HarmonyLog {
    param([string]$Msg, [string]$Level = 'INFO')
    $t = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $HarmonyLog -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ§© Initialisation & chargement des fichiers sources
# ====================================================================
function Initialize-HarmonyNetwork {
    Write-HarmonyLog "=== Initialisation du rÃ©seau d'harmonie ==="
    if (!(Test-Path $HarmonyState)) {
        @{ Date = (Get-Date); HarmonyScore = 0; EmotionBalance = 0; CognitiveLoad = 0; SystemStability = 0 } | ConvertTo-Json -Depth 3 | Out-File $HarmonyState -Encoding utf8
    }
}

function Get-HarmonyInputs {
    $EmotionFile  = Join-Path $MemoryDir 'EmotionHistory.json'
    $SystemFile   = Join-Path $MemoryDir 'SystemMetrics.json'
    $LearningFile = Join-Path $MemoryDir 'LearningWeights.json'

    $data = [ordered]@{}
    foreach ($f in @($EmotionFile, $SystemFile, $LearningFile)) {
        if (Test-Path $f) {
            try { $data[$(Split-Path $f -LeafBase)] = Get-Content $f -Raw | ConvertFrom-Json }
            catch { Write-HarmonyLog "Erreur lecture fichier $f : $_" 'WARN' }
        }
    }
    return $data
}

# ====================================================================
# ðŸ“Š Calculs & corrÃ©lation
# ====================================================================
function Get-EmotionBalance($data) {
    if ($null -eq $data.EmotionHistory) { return 50 }
    $values = $data.EmotionHistory | ForEach-Object { $_.intensitÃ© }
    return [math]::Round((($values | Measure-Object -Average).Average), 2)
}

function Get-SystemStability($data) {
    if ($null -eq $data.SystemMetrics) { return 60 }
    $cpu = $data.SystemMetrics.CPU
    $ram = $data.SystemMetrics.RAM
    $temp = $data.SystemMetrics.Temp
    $stability = 100 - ((($cpu + $ram + $temp) / 3) * 0.8)
    return [math]::Max([math]::Min($stability,100),0)
}

function Get-CognitiveLoad($data) {
    if ($null -eq $data.LearningWeights) { return 50 }
    $weights = $data.LearningWeights.Values
    $avg = ($weights | Measure-Object -Average).Average
    return [math]::Round($avg,2)
}

function Compute-HarmonyScore($emotion,$system,$cognitive) {
    $score = ($emotion * 0.4) + ($system * 0.3) + ((100 - $cognitive) * 0.3)
    return [math]::Round($score,2)
}

# ====================================================================
# ðŸ”„ Ajustement automatique & auto-apprentissage
# ====================================================================
function Invoke-HarmonyAdjustment($score,$threshold=60) {
    if ($score -lt $threshold) {
        Write-HarmonyLog "âš ï¸ DÃ©sÃ©quilibre dÃ©tectÃ© : Score=$score â€” RÃ©ajustement des poids."
        $LearningFile = Join-Path $MemoryDir 'LearningWeights.json'
        if (Test-Path $LearningFile) {
            try {
                $weights = Get-Content $LearningFile -Raw | ConvertFrom-Json
                $weights.Values = $weights.Values | ForEach-Object { $_ * 0.95 }
                $weights | ConvertTo-Json -Depth 3 | Out-File $LearningFile -Encoding utf8
            } catch { Write-HarmonyLog "Erreur ajustement LearningWeights : $_" 'ERROR' }
        }
    } else {
        Write-HarmonyLog "âœ… SystÃ¨me stable : Score=$score"
    }
}

# ====================================================================
# ðŸ’¾ Sauvegarde & archivage
# ====================================================================
function Save-HarmonyState($score,$emotion,$system,$cognitive) {
    $state = [ordered]@{
        Date = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        HarmonyScore = $score
        EmotionBalance = $emotion
        SystemStability = $system
        CognitiveLoad = $cognitive
    }
    $state | ConvertTo-Json -Depth 4 | Out-File $HarmonyState -Encoding utf8
    Write-HarmonyLog "Ã‰tat sauvegardÃ© : Score=$score"
}

function Archive-HarmonyState {
    $ArchiveDir = Join-Path $MemoryDir 'Archives/Harmony'
    if (!(Test-Path $ArchiveDir)) { New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null }
    $date = (Get-Date -Format 'yyyyMMdd_HHmm')
    Copy-Item $HarmonyState (Join-Path $ArchiveDir "HarmonyState_$date.json") -Force
}

# ====================================================================
# ðŸ–¥ï¸ Communication avec Cockpit & interfaces
# ====================================================================
function Send-HarmonyToCockpit($score) {
    $CockpitModule = Join-Path $ModulesDir 'Cockpit.Signal.psm1'
    if (Test-Path $CockpitModule) {
        Import-Module $CockpitModule -Force -Global
        if (Get-Command Send-CockpitSignal -ErrorAction SilentlyContinue) {
            $color = if ($score -gt 75) { 'green' } elseif ($score -gt 50) { 'yellow' } else { 'red' }
            Send-CockpitSignal -Indicator 'HarmonyScore' -Value $score -Color $color
        }
    }
}

# ====================================================================
# ðŸ”® Fonctions dâ€™Ã©volution future (prÃ©-dÃ©clarÃ©es)
# ====================================================================
function Predict-HarmonyTrends {
    Write-HarmonyLog "PrÃ©vision des tendances dâ€™harmonie (placeholder)."
}
function Sync-HarmonyWithEmotionEngine {
    Write-HarmonyLog "Synchronisation bidirectionnelle EmotionEngine (placeholder)."
}
function Evaluate-SelfHarmonyLevel {
    Write-HarmonyLog "Ã‰valuation du niveau de conscience interne (placeholder)."
}
function AutoTune-HarmonyWeights {
    Write-HarmonyLog "Auto-ajustement prÃ©dictif des pondÃ©rations (placeholder)."
}
function Integrate-SensorNetwork {
    Write-HarmonyLog "Connexion rÃ©seau de capteurs physiques (placeholder)."
}

# ====================================================================
# ðŸš€ Fonction maÃ®tre
# ====================================================================
function Invoke-AthenaHarmonyNetwork {
    Write-Host "`nðŸŽµ DÃ©marrage du rÃ©seau dâ€™harmonie..." -ForegroundColor Cyan
    Initialize-HarmonyNetwork
    $inputs = Get-HarmonyInputs
    $emotion = Get-EmotionBalance $inputs
    $system  = Get-SystemStability $inputs
    $cognitive = Get-CognitiveLoad $inputs
    $score = Compute-HarmonyScore $emotion $system $cognitive
    Save-HarmonyState $score $emotion $system $cognitive
    Invoke-HarmonyAdjustment $score
    Send-HarmonyToCockpit $score
    Write-HarmonyLog "Cycle complet exÃ©cutÃ© (Score=$score)"
    return $score
}

# ====================================================================
# ðŸ”š Exportation
# ====================================================================
Export-ModuleMember -Function Invoke-AthenaHarmonyNetwork, Initialize-HarmonyNetwork, Compute-HarmonyScore, Invoke-HarmonyAdjustment, Save-HarmonyState, Send-HarmonyToCockpit

Write-Host "ðŸ§  Module Athena.HarmonyNetwork.psm1 chargÃ© (v1.0-HarmonyCore-Full)." -ForegroundColor Green


