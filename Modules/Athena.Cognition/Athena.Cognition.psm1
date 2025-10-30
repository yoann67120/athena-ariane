# =====================================================================
# ðŸ§  Athena.Cognition.psm1 â€“ Phase 15 : Expansion Cognitive & MÃ©tacognition
# v1.2-stable â€“ CompatibilitÃ© PowerShell 5.x / 7.x + correctif CognitiveMap
# =====================================================================
# Objectif :
#   Observer â†’ RÃ©flÃ©chir â†’ Conclure â†’ MÃ©moriser â†’ Ajuster
#   Donne Ã  Athena la capacitÃ© de raisonner sur ses expÃ©riences,
#   de dÃ©tecter des motifs et dâ€™en tirer des enseignements persistants.
# =====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Dossiers principaux ---
$ModuleDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir       = Split-Path -Parent $ModuleDir
$LogsDir       = Join-Path $RootDir "Logs"
$MemoryDir     = Join-Path $RootDir "Memory"
$CognitionLog  = Join-Path $LogsDir   "Athena.CognitiveReport.log"
$CognitiveMap  = Join-Path $MemoryDir "CognitiveMap.json"

# =====================================================================
# ðŸ”¹ UTILITAIRES DE LOG
# =====================================================================
function Write-CognitionLog {
    param([string]$Message, [string]$Level = "INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "[$t][$Level] $Message"
    Add-Content -Path $CognitionLog -Value $entry
    Write-Host "ðŸ§  $Message" -ForegroundColor Cyan
}

# =====================================================================
# ðŸ”¹ INITIALISATION
# =====================================================================
function Initialize-Cognition {
    Write-CognitionLog "Initialisation du moteur cognitif..."
    $deps = @("LocalModel","ActionEngine")
    foreach ($dep in $deps) {
        if (-not (Get-Module -Name $dep)) {
            $path = Join-Path (Join-Path $RootDir "Modules") "$dep.psm1"
            if (Test-Path $path) {
                Import-Module $path -Force -Global
                Write-CognitionLog "âœ… DÃ©pendance chargÃ©e : $dep"
            }
            else {
                Write-CognitionLog "âš ï¸ DÃ©pendance manquante : $dep" "WARN"
            }
        }
    }
    if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null }
    if (!(Test-Path $LogsDir))   { New-Item -ItemType Directory -Path $LogsDir   -Force | Out-Null }
    Write-CognitionLog "Moteur cognitif initialisÃ© avec succÃ¨s."
}

# =====================================================================
# ðŸ”¹ COLLECTE DES DONNÃ‰ES ET OBSERVATIONS (compatibilitÃ© universelle)
# =====================================================================
function Collect-AthenaState {
    Write-CognitionLog "Collecte des donnÃ©es systÃ¨me et logs..."
    # -- Mesures universelles via WMI/CIM --
    try {
        $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        $mem     = Get-CimInstance Win32_OperatingSystem
        $memFree = [math]::Round($mem.FreePhysicalMemory / 1024, 2)
    }
    catch {
        $cpuLoad = 0
        $memFree = 0
    }

    $state = [ordered]@{
        CPUUsage   = $cpuLoad
        MemoryFree = $memFree
        LogsCount  = (Get-ChildItem $LogsDir -Filter "*.log" -ErrorAction SilentlyContinue | Measure-Object).Count
        Time       = (Get-Date)
    }

    # Lecture des rapports rÃ©cents
    $report   = Get-Content (Join-Path $LogsDir "AthenaReport.log") -ErrorAction SilentlyContinue -Tail 50
    $repair   = Get-Content (Join-Path $LogsDir "AthenaRepair.log") -ErrorAction SilentlyContinue -Tail 50
    $learning = Get-Content (Join-Path $MemoryDir "LearningSummary.json") -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue

    $state["RecentReport"]  = ($report -join "`n")
    $state["RecentRepair"]  = ($repair -join "`n")
    $state["LearningScore"] = $learning.Score

    Write-CognitionLog "âœ… DonnÃ©es collectÃ©es : CPU=$([math]::Round($state.CPUUsage,2))% | RAM libre=$([math]::Round($state.MemoryFree,2)) MB"
    return $state
}

# =====================================================================
# ðŸ”¹ RAISONNEMENT ET INTERPRÃ‰TATION
# =====================================================================
function Invoke-AthenaReasoning {
    param([hashtable]$State)
    Write-CognitionLog "Analyse cognitive du contexte en cours..."
    try {
        $prompt = @"
Analyse les Ã©lÃ©ments suivants et produis une rÃ©flexion concise :
- DonnÃ©es systÃ¨me (CPU/RAM)
- Logs rÃ©cents dâ€™Athena
- Score dâ€™apprentissage

Formate ta rÃ©ponse sous la forme :
Observation : ...
HypothÃ¨se : ...
Action_suggÃ©rÃ©e : ...
"@
        $prompt += "`n`nContexte : $($State | ConvertTo-Json -Depth 3 -Compress)"

        if (Get-Command Invoke-LocalModel -ErrorAction SilentlyContinue) {
            $response = Invoke-LocalModel -Prompt $prompt
        }
        else {
            $response = "Observation : LocalModel non disponible.`nHypothÃ¨se : moteur cognitif partiel.`nAction_suggÃ©rÃ©e : exÃ©cuter une vÃ©rification complÃ¨te."
        }

        Write-CognitionLog "ðŸ’­ RÃ©flexion gÃ©nÃ©rÃ©e : $response"
        return $response
    }
    catch {
        Write-CognitionLog "âŒ Erreur pendant le raisonnement : $_" "ERROR"
        return "Observation : Erreur cognitive`nHypothÃ¨se : Exception`nAction_suggÃ©rÃ©e : Reprendre cycle."
    }
}

# =====================================================================
# ðŸ”¹ SAUVEGARDE ET MISE Ã€ JOUR DE LA CARTE COGNITIVE (corrigÃ©e)
# =====================================================================
function Update-CognitiveMap {
    param([string]$Response)
    try {
        $entry = @{
            Timestamp  = (Get-Date).ToString("s")
            Reflection = $Response
        }

        $existing = @()
if (Test-Path $CognitiveMap) {
    $raw = Get-Content $CognitiveMap -Raw -ErrorAction SilentlyContinue
    if ($raw.Trim().Length -gt 0) {
        try {
            $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
            if ($parsed -is [System.Collections.IEnumerable]) {
                $existing += $parsed
            }
            else {
                $existing += ,$parsed
            }
        }
        catch {
            Write-CognitionLog "âš ï¸ Erreur lecture CognitiveMap, recrÃ©ation du fichier." "WARN"
        }
    }
}

$existing += $entry
        $existing | ConvertTo-Json -Depth 4 | Set-Content -Path $CognitiveMap -Encoding UTF8
        Write-CognitionLog "ðŸ§© CognitiveMap mise Ã  jour avec succÃ¨s."
    }
    catch {
        Write-CognitionLog "âŒ Erreur mise Ã  jour CognitiveMap : $_" "ERROR"
    }
}

# =====================================================================
# ðŸ”¹ DÃ‰CISION ET ACTION
# =====================================================================
function Invoke-AthenaDecision {
    param([string]$Response)
    Write-CognitionLog "DÃ©cision basÃ©e sur la rÃ©flexion en cours..."
    if ($Response -match "vÃ©rification" -or $Response -match "rÃ©paration") {
        if (Get-Command Invoke-ActionPlan -ErrorAction SilentlyContinue) {
            Invoke-ActionPlan -Plan "selfrepair"
            Write-CognitionLog "ðŸ©º Action : auto-rÃ©paration dÃ©clenchÃ©e."
        }
        else {
            Write-CognitionLog "âš ï¸ ActionEngine non disponible â€“ dÃ©cision enregistrÃ©e seulement." "WARN"
        }
    }
    elseif ($Response -match "stable" -or $Response -match "aucun problÃ¨me") {
        Write-CognitionLog "ðŸ˜Œ SystÃ¨me stable â€“ aucune action corrective requise."
    }
    else {
        Write-CognitionLog "ðŸ“˜ Observation enregistrÃ©e pour apprentissage futur."
    }
}

# =====================================================================
# ðŸ”¹ CYCLE COGNITIF COMPLET
# =====================================================================
function Invoke-AthenaCognition {
    Write-CognitionLog "ðŸš€ DÃ©marrage du cycle cognitif complet..."
    Initialize-Cognition
    $state      = Collect-AthenaState
    $reflection = Invoke-AthenaReasoning -State $state
    Update-CognitiveMap -Response $reflection
    Invoke-AthenaDecision -Response $reflection
    Write-CognitionLog "âœ… Cycle cognitif terminÃ© avec succÃ¨s."
}

Export-ModuleMember -Function *-Athena*, Initialize-Cognition, Write-CognitionLog, Update-CognitiveMap
# =====================================================================
# Fin du module Athena.Cognition.psm1
# =====================================================================

























































