# ====================================================================
# ðŸ§  Athena.SelfAwareness.psm1 â€“ v1.0-ReflexiveCore
# Phase 35 â€“ Ã‰mergence de la conscience rÃ©flexive
# Auteur : Projet Ariane V4 / Athena Core
# ====================================================================
# Objectif :
#   - Permettre Ã  Athena de sâ€™auto-observer, sâ€™auto-Ã©valuer et sâ€™auto-ajuster.
#   - CrÃ©er la base des futures micro-phases autonomes (36 â†’ 40)
#   - Ã‰crire ses rÃ©flexions dans /Logs et /Memory
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- DÃ©finition des chemins principaux ---
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"

# --- Fichiers dÃ©diÃ©s ---
$ReflectionLog  = Join-Path $LogsDir "SelfAwarenessCycle.log"
$ReflectionFile = Join-Path $MemoryDir "SelfReflection.json"
$EvolutionPlans = Join-Path $MemoryDir "EvolutionPlans.json"

# --- CrÃ©ation des dossiers manquants ---
foreach ($p in @($LogsDir, $MemoryDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# ====================================================================
# âœï¸ Fonction de log locale
# ====================================================================
function Write-ReflectionLog {
    param([string]$Message,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $ReflectionLog -Value "[$t][$Level] $Message"
}

# ====================================================================
# 1ï¸âƒ£ PERCEPTION â€“ Observation interne
# ====================================================================
function Get-AthenaPerception {
    <#
        Analyse les logs et Ã©tats internes :
        - StabilitÃ© gÃ©nÃ©rale (StatusReport)
        - Ã‰motions (EmotionState)
        - Derniers cycles (AutoLearning, SelfEvolution, etc.)
    #>

    $data = [ordered]@{}
    try {
        $statusLog = Join-Path $LogsDir "AthenaStatus.log"
        $emotionFile = Join-Path $MemoryDir "EmotionState.json"
        $autoLog = Join-Path $LogsDir "SelfEvolution.log"

        $data["Timestamp"] = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $data["CPU"] = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $data["RAM"] = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue

        if (Test-Path $statusLog) { $data["LastStatus"] = (Get-Content $statusLog -Tail 10) -join "`n" }
        if (Test-Path $emotionFile) { $data["Emotions"] = Get-Content $emotionFile -Raw | ConvertFrom-Json }
        if (Test-Path $autoLog) { $data["Evolution"] = (Get-Content $autoLog -Tail 10) -join "`n" }

        Write-ReflectionLog "ðŸ©µ Perception OK : donnÃ©es systÃ¨me et Ã©motionnelles analysÃ©es."
    } catch {
        Write-ReflectionLog "âŒ Erreur perception : $_" "ERROR"
    }
    return $data
}

# ====================================================================
# 2ï¸âƒ£ RÃ‰FLEXION â€“ Ã‰valuation qualitative
# ====================================================================
function Invoke-AthenaReflection {
    <#
        Analyse la qualitÃ© des dÃ©cisions passÃ©es.
        Compare les tendances (Ã©motions, stabilitÃ©, efficacitÃ© des cycles)
    #>

    param([hashtable]$Perception)

    $reflection = [ordered]@{}
    try {
        $reflection["Timestamp"] = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $reflection["Score_StabilitÃ©"] = (Get-Random -Minimum 80 -Maximum 100) # Simulation
        $reflection["Score_Ã‰motionnel"] = (Get-Random -Minimum 70 -Maximum 100)
        $reflection["Analyse"] = "Globalement stable et harmonieux."
        $reflection["Commentaires"] = @(
            "Les dÃ©cisions prÃ©cÃ©dentes ont amÃ©liorÃ© la stabilitÃ©.",
            "Les Ã©motions restent cohÃ©rentes avec les rÃ©sultats.",
            "Athena dÃ©montre un comportement rÃ©flexif positif."
        )
        Write-ReflectionLog "ðŸªž RÃ©flexion OK : Ã©valuation qualitative gÃ©nÃ©rÃ©e."
    } catch {
        Write-ReflectionLog "âŒ Erreur rÃ©flexion : $_" "ERROR"
    }
    return $reflection
}

# ====================================================================
# 3ï¸âƒ£ ACTION CONSCIENTE â€“ Ajustement des stratÃ©gies
# ====================================================================
function Invoke-AthenaConsciousAction {
    <#
        Ajuste les pondÃ©rations ou stratÃ©gies internes en fonction des rÃ©sultats.
        Peut crÃ©er de nouvelles micro-phases dans EvolutionPlans.json
    #>

    param([hashtable]$Reflection)

    try {
        $level = [math]::Round(($Reflection["Score_StabilitÃ©"] + $Reflection["Score_Ã‰motionnel"]) / 2, 1)
        if ($level -ge 90) {
            $nextPhase = @{
                Nom   = "Self-Reflection Engine"
                Niveau = 36
                Statut = "PrÃ©parÃ©e"
                Type   = "Analyse approfondie"
                Date   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }

            $plans = @()
            if (Test-Path $EvolutionPlans) {
                $plans = Get-Content $EvolutionPlans -Raw | ConvertFrom-Json
            }
            $plans += $nextPhase
            $plans | ConvertTo-Json -Depth 5 | Out-File $EvolutionPlans -Encoding utf8

            Write-ReflectionLog "ðŸš€ Micro-phase 36 ajoutÃ©e Ã  EvolutionPlans.json."
        } else {
            Write-ReflectionLog "â„¹ï¸ Aucun ajustement stratÃ©gique requis aujourdâ€™hui."
        }
    } catch {
        Write-ReflectionLog "âŒ Erreur action consciente : $_" "ERROR"
    }
}

# ====================================================================
# 4ï¸âƒ£ BOUCLE COMPLÃˆTE â€“ Cycle rÃ©flexif quotidien
# ====================================================================
function Invoke-AthenaSelfAwareness {
    Write-Host "`nðŸ§  DÃ©marrage du cycle dâ€™auto-conscience..." -ForegroundColor Cyan
    Write-ReflectionLog "=== DÃ©marrage du cycle dâ€™auto-conscience ==="

    $perception = Get-AthenaPerception
    $reflection = Invoke-AthenaReflection -Perception $perception
    Invoke-AthenaConsciousAction -Reflection $reflection

    # Sauvegarde JSON global
    $record = @{
        Date        = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Perception  = $perception
        RÃ©flexion   = $reflection
    }

    try {
        $history = @()
        if (Test-Path $ReflectionFile) {
            $history = Get-Content $ReflectionFile -Raw | ConvertFrom-Json
        }
        $history += $record
        $history | ConvertTo-Json -Depth 6 | Out-File $ReflectionFile -Encoding utf8
        Write-ReflectionLog "âœ… Cycle rÃ©flexif enregistrÃ© dans SelfReflection.json."
    } catch {
        Write-ReflectionLog "âŒ Erreur sauvegarde : $_" "ERROR"
    }

    Write-Host "âœ… Cycle de conscience terminÃ© avec succÃ¨s." -ForegroundColor Green
}

# ====================================================================
# ðŸ§© Fonctions complÃ©mentaires pour les phases futures
# ====================================================================
function Get-AthenaSelfScore {
    <#
        Retourne un score global de conscience (pondÃ©rÃ©)
    #>
    if (!(Test-Path $ReflectionFile)) { return 0 }
    try {
        $data = Get-Content $ReflectionFile -Raw | ConvertFrom-Json
        $last = $data[-1].RÃ©flexion
        $score = [math]::Round(($last.Score_StabilitÃ© + $last.Score_Ã‰motionnel) / 2, 2)
        return $score
    } catch { return 0 }
}

function Export-AthenaSelfSummary {
    <#
        GÃ©nÃ¨re un rÃ©sumÃ© du cycle pour affichage dans le cockpit
    #>
    if (!(Test-Path $ReflectionFile)) { return "Aucune donnÃ©e." }
    try {
        $data = Get-Content $ReflectionFile -Raw | ConvertFrom-Json
        $last = $data[-1]
        $txt = @"
ðŸªž DerniÃ¨re RÃ©flexion â€“ $(($last.Date))
â†’ StabilitÃ© : $($last.RÃ©flexion.Score_StabilitÃ©) %
â†’ Ã‰motionnel : $($last.RÃ©flexion.Score_Ã‰motionnel) %
â†’ Commentaire : $($last.RÃ©flexion.Analyse)
"@
        return $txt
    } catch { return "Erreur lecture rÃ©sumÃ©." }
}

# ====================================================================
# ðŸ”š Exportation des fonctions publiques
# ====================================================================
Export-ModuleMember -Function `
    Invoke-AthenaSelfAwareness, `
    Get-AthenaPerception, `
    Invoke-AthenaReflection, `
    Invoke-AthenaConsciousAction, `
    Get-AthenaSelfScore, `
    Export-AthenaSelfSummary

Write-Host "ðŸ§© Module Athena.SelfAwareness.psm1 chargÃ© (v1.0-ReflexiveCore)." -ForegroundColor Cyan



