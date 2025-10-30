# ====================================================================
# ðŸ§  Athena.SelfCoordinator.psm1
# Version : v1.0-CoordinationEngine-ExtendedFutureReady
# Auteur : Yoann Rousselle / Athena Core
# RÃ´le :
#   - CÅ“ur de coordination entre les pÃ´les Cognition / Ã‰motion / SystÃ¨me
#   - DÃ©cide automatiquement quel moteur activer selon le contexte global
#   - PrÃ©pare le terrain pour la conscience rÃ©flexive (Phase 35+)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ====================================================================
# ðŸ“ Dossiers principaux
# ====================================================================
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$ModulesDir = Join-Path $RootDir "Modules"

$EvolutionPlan = Join-Path $MemoryDir "EvolutionPlans.json"
$CoordLog      = Join-Path $LogsDir "CoordinationCycle.log"

foreach ($p in @($MemoryDir,$LogsDir)) { if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null } }

# ====================================================================
# âœï¸ Fonction gÃ©nÃ©rique de log
# ====================================================================
function Write-CoordinationLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $CoordLog -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ§© Lecture des Ã©tats internes (Cognition / Emotion / SystÃ¨me)
# ====================================================================
function Get-CognitiveState {
    $path = Join-Path $MemoryDir "LearningHistory.json"
    if (Test-Path $path) { return (Get-Content $path -Raw | ConvertFrom-Json) }
    return @{Score=0; LastCycle="None"}
}

function Get-EmotionalState {
    $path = Join-Path $MemoryDir "HarmonyState.json"
    if (Test-Path $path) { return (Get-Content $path -Raw | ConvertFrom-Json) }
    return @{Harmony=0; Mood="Stable"}
}

function Get-SystemState {
    $path = Join-Path $MemoryDir "SystemMetrics.json"
    if (Test-Path $path) { return (Get-Content $path -Raw | ConvertFrom-Json) }
    return @{CPU=0; RAM=0; Stability=0}
}

# ====================================================================
# ðŸ§® Calcul du score global de stabilitÃ©
# PondÃ©ration : 50% systÃ¨me / 30% harmonie / 20% apprentissage
# ====================================================================
function Get-StabilityScore {
    $cog = Get-CognitiveState
    $emo = Get-EmotionalState
    $sys = Get-SystemState

    $score = [math]::Round(
        ($sys.Stability * 0.5) + ($emo.Harmony * 0.3) + ($cog.Score * 0.2),
        2
    )

    Write-CoordinationLog "ðŸ§® Score global calculÃ© : $score%"
    return $score
}

# ====================================================================
# ðŸ§­ Analyse de prioritÃ© : dÃ©termine quel moteur doit sâ€™activer
# ====================================================================
function Get-PriorityAction {
    $sys = Get-SystemState
    $emo = Get-EmotionalState
    $cog = Get-CognitiveState

    if ($sys.Stability -lt 60) { return "Repair" }
    elseif ($emo.Harmony -lt 50) { return "Harmony" }
    elseif ($cog.Score -lt 50) { return "Learning" }
    else { return "Idle" }
}

# ====================================================================
# âš™ï¸ DÃ©clencheur de moteurs
# ====================================================================
function Invoke-CoordinationAction {
    param(
        [string]$action,
        [double]$score = 0
    )

    switch ($action) {
        "Repair" {
            Write-CoordinationLog "ðŸ”§ PrioritÃ© = RÃ©paration"
            $mod = Join-Path $ModulesDir "SelfRepair.psm1"
            if (Test-Path $mod) { Import-Module $mod -Force -Global; Invoke-SelfRepair }
        }
        "Harmony" {
            Write-CoordinationLog "ðŸŽµ PrioritÃ© = Harmonie"
            $mod = Join-Path $ModulesDir "Athena.HarmonyNetwork.psm1"
            if (Test-Path $mod) { Import-Module $mod -Force -Global; Invoke-AthenaHarmony }
        }
        "Learning" {
            Write-CoordinationLog "ðŸ“š PrioritÃ© = Apprentissage"
            $mod = Join-Path $ModulesDir "Athena.AutoLearning.psm1"
            if (Test-Path $mod) { Import-Module $mod -Force -Global; Invoke-AthenaLearning }
        }
        "Idle" {
            Write-CoordinationLog "ðŸ’¤ Aucun moteur prioritaire â€“ passage en veille cognitive."
        }
        default {
            Write-CoordinationLog "âš ï¸ Action inconnue : $action"
        }
    }
# ====================================================================
# ðŸ¤ Appel du moteur d'intÃ©gration (IntegrationAdvisor)
# ====================================================================
try {
    $AdvisorModule = Join-Path $ModulesDir "Athena.IntegrationAdvisor.psm1"
    if (Test-Path $AdvisorModule) {
        Import-Module $AdvisorModule -Force -Global
        Write-CoordinationLog "ðŸ” Appel de Athena.IntegrationAdvisor.psm1..."
        $Context = "CycleCoordination-" + $action + "-Score:" + $score
        Invoke-AthenaIntegrationAdvisor -Context $Context
        Write-CoordinationLog "ðŸ¤– IntÃ©gration Advisor exÃ©cutÃ© aprÃ¨s action : $action"
        Write-CoordinationLog "âœ… Analyse d'intÃ©gration terminÃ©e."
    }
    else {
        Write-CoordinationLog "âš ï¸ Module Athena.IntegrationAdvisor.psm1 non trouvÃ©."
    }
}
catch {
    Write-CoordinationLog "âŒ Erreur lors de l'appel du moteur d'intÃ©gration : $($_.Exception.Message)"
}
}

# ====================================================================
# ðŸ§© GÃ©nÃ©ration / mise Ã  jour du plan dâ€™Ã©volution
# ====================================================================
function Update-EvolutionPlan {
    param([string]$NextPhase,[string]$Reason)

    $plan = @()
    if (Test-Path $EvolutionPlan) {
        try { $plan = Get-Content $EvolutionPlan -Raw | ConvertFrom-Json }
        catch { $plan = @() }
    }

    $entry = [pscustomobject]@{
        Date       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        NextPhase  = $NextPhase
        Motif      = $Reason
        Stability  = (Get-StabilityScore)
    }

    $plan += $entry
    $plan | ConvertTo-Json -Depth 4 | Out-File $EvolutionPlan -Encoding utf8
    Write-CoordinationLog "ðŸ§± Nouveau plan dâ€™Ã©volution enregistrÃ© : $NextPhase ($Reason)"
}

# ====================================================================
# ðŸš€ Cycle principal de coordination
# ====================================================================
function Invoke-AthenaCoordinationCycle {
    Write-Host "`nðŸ§© Lancement du cycle de coordination interne..." -ForegroundColor Cyan
    Write-CoordinationLog "=== Nouveau cycle lancÃ© ==="

    $score = Get-StabilityScore
    $action = Get-PriorityAction
    Write-Host "ðŸŽ¯ Action prioritaire dÃ©tectÃ©e : $action ($score%)" -ForegroundColor Yellow

   Invoke-CoordinationAction -Action $action -Score $score

    $phaseNext = switch ($action) {
        "Repair"   { "Phase-SelfRepair" }
        "Harmony"  { "Phase-HarmonyAdjust" }
        "Learning" { "Phase-LearningDeep" }
        default    { "Phase-Idle" }
    }

    Update-EvolutionPlan -NextPhase $phaseNext -Reason "CycleCoordination-$action"

    Write-Host "âœ… Cycle de coordination terminÃ©." -ForegroundColor Green
    Write-CoordinationLog "=== Fin du cycle ==="
}

# ====================================================================
# ðŸ§  Fonctions futures â€“ Niveaux 5 â†’ 6
# ====================================================================

# RÃ©flexion interne sur les dÃ©cisions passÃ©es
function Invoke-ReflectionAnalysis {
    Write-CoordinationLog "ðŸªž Analyse rÃ©flexive des dÃ©cisions prÃ©cÃ©dentes..."
    # Lecture des 5 derniers cycles
    if (Test-Path $CoordLog) {
        $recent = Get-Content $CoordLog | Select-String "\[INFO\]" | Select-Object -Last 5
        Write-CoordinationLog "ðŸ§© DerniÃ¨res dÃ©cisions : $($recent -join ', ')"
    }
}

# Auto-optimisation du poids de pondÃ©ration (future AI weighting)
function Optimize-DecisionWeights {
    param([float]$StabWeight=0.5,[float]$HarmWeight=0.3,[float]$LearnWeight=0.2)
    Write-CoordinationLog "âš™ï¸ Optimisation des pondÃ©rations : Stab=$StabWeight, Harm=$HarmWeight, Learn=$LearnWeight"
    # futur : adaptation dynamique selon historique de performance
}

# Simulation de cycle futur (anticipation)
function Simulate-FutureCycles {
    param([int]$Count=3)
    Write-CoordinationLog "ðŸ”® Simulation de $Count cycles futurs..."
    for ($i=1;$i -le $Count;$i++) {
        $pred = Get-Random -Minimum 70 -Maximum 100
        Write-CoordinationLog "Cycle $i simulÃ© â†’ stabilitÃ© prÃ©visionnelle : $pred%"
    }
}

# Synchronisation du Cockpit visuel
function Update-CockpitIndicator {
    $msg = "ðŸ§© Coordination Active â€“ Auto-Planning Enabled"
    Write-CoordinationLog $msg
    $notifyModule = Join-Path $ModulesDir "Cockpit.Notify.psm1"
    if (Test-Path $notifyModule) {
        Import-Module $notifyModule -Force -Global
        if (Get-Command Invoke-CockpitNotify -ErrorAction SilentlyContinue) {
            Invoke-CockpitNotify -Message $msg -Tone "pulse" -Color "green"
        }
    }
}

# Ã‰volution auto-planifiÃ©e (Phase 36+)
function Invoke-AutoEvolutionPlan {
    Write-CoordinationLog "ðŸš€ DÃ©clenchement du plan dâ€™Ã©volution auto-planifiÃ©..."
    if (Test-Path $EvolutionPlan) {
        $plan = Get-Content $EvolutionPlan -Raw | ConvertFrom-Json
        $last = $plan | Select-Object -Last 1
        Write-Host "ðŸ§­ Prochaine phase prÃ©vue : $($last.NextPhase)" -ForegroundColor Cyan
    }
}
# RÃ©sumÃ© rapide des 5 derniers cycles
function Get-CoordinationSummary {
    Write-Host "`nðŸ“˜ RÃ©capitulatif des 5 derniers cycles :" -ForegroundColor Cyan
    if (!(Test-Path $CoordLog)) {
        Write-Host "âš ï¸ Aucun cycle trouvÃ© dans CoordinationCycle.log" -ForegroundColor Yellow
        return
    }
    $lines = Get-Content $CoordLog | Select-String "PrioritÃ©|Score|IntÃ©gration" | Select-Object -Last 30
    if ($lines) {
        $lines | ForEach-Object { Write-Host $_.Line -ForegroundColor Gray }
    } else {
        Write-Host "Aucun dÃ©tail rÃ©cent trouvÃ©." -ForegroundColor DarkGray
    }
}

# ====================================================================
# ðŸ”š Export des fonctions
# ====================================================================
Export-ModuleMember -Function *-AthenaCoordination*,Get-*,Invoke-*,Update-*,Simulate-*,Optimize-*,Invoke-AutoEvolutionPlan,Invoke-ReflectionAnalysis,Update-CockpitIndicator
Write-Host "ðŸ§  Module Athena.SelfCoordinator.psm1 chargÃ© (v1.0-CoordinationEngine-ExtendedFutureReady)." -ForegroundColor Cyan



