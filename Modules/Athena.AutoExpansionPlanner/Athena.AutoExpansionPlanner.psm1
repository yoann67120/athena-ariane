# ====================================================================
# ðŸ§± Athena.AutoExpansionPlanner.psm1 â€“ v1.0-Planning-Core
# --------------------------------------------------------------------
# Objectif :
#   GÃ©nÃ©rer automatiquement les plans et fichiers de phase suivants
#   en fonction des modules dÃ©tectÃ©s, de leur Ã©tat et des besoins
#   issus du moteur SelfEvolution.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === RÃ©pertoires ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ConfigDir  = Join-Path $RootDir "Config"
$DocsDir    = $RootDir
$LogFile    = Join-Path $LogsDir "AutoExpansionPlanner.log"
$DiffFile   = Join-Path $MemoryDir "SelfEvolutionDiff.json"
$PlanFile   = Join-Path $MemoryDir "NextEvolutionPlan.json"

foreach ($p in @($LogsDir,$MemoryDir,$ConfigDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Write-PlanLog {
    param([string]$Msg,[string]$Level="INFO")
    $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# 1ï¸âƒ£ Lecture des diffÃ©rences d'Ã©volution
# ====================================================================
function Get-EvolutionChanges {
    if (!(Test-Path $DiffFile)) {
        Write-PlanLog "âŒ Aucun rapport SelfEvolutionDiff.json trouvÃ©." "ERROR"
        return $null
    }
    try {
        $data = Get-Content $DiffFile -Raw | ConvertFrom-Json
        Write-PlanLog "Rapport SelfEvolutionDiff chargÃ©."
        return $data
    } catch {
        Write-PlanLog "âš ï¸ Erreur lecture fichier diff : $_" "WARN"
        return $null
    }
}

# ====================================================================
# 2ï¸âƒ£ DÃ©termination du numÃ©ro de phase suivante
# ====================================================================
function Get-NextPhaseNumber {
    $files = Get-ChildItem -Path $DocsDir -Filter "ArianeV4_Structure_Phase*.txt"
    if ($files) {
        $nums = $files.Name | ForEach-Object { ($_ -replace '\D','') -as [int] } | Where-Object { $_ -gt 0 }
        if ($nums) { return ($nums | Measure-Object -Maximum).Maximum + 1 }
    }
    return 1
}

# ====================================================================
# 3ï¸âƒ£ GÃ©nÃ©ration du plan d'Ã©volution JSON
# ====================================================================
function Generate-NextEvolutionPlan {
    Write-PlanLog "GÃ©nÃ©ration du plan d'Ã©volution..."
    $changes = Get-EvolutionChanges
    if (-not $changes) { Write-PlanLog "âš ï¸ Aucun changement dÃ©tectÃ©."; return }

    $plan = [pscustomobject]@{
        Date              = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Phase_Suivante    = "Phase $((Get-NextPhaseNumber))"
        Modules_Ajoutes   = $changes.Modules_Ajoutes
        Modules_Modifies  = $changes.Modules_Modifies
        Modules_Supprimes = $changes.Modules_Supprimes
        Objectif_Global   = "Analyse et adaptation automatique Ã  partir des changements dÃ©tectÃ©s"
        Etat              = "PlanifiÃ©"
    }

    $plan | ConvertTo-Json -Depth 5 | Out-File $PlanFile -Encoding utf8
    Write-PlanLog "âœ… Nouveau plan d'Ã©volution gÃ©nÃ©rÃ© ($PlanFile)"
    return $plan
}

# ====================================================================
# 4ï¸âƒ£ GÃ©nÃ©ration automatique du fichier ArianeV4_Structure_PhaseXX.txt
# ====================================================================
function Generate-PhaseFile {
    param([object]$Plan)
    if (-not $Plan) { Write-PlanLog "âš ï¸ Aucun plan d'Ã©volution trouvÃ©."; return }

    $phaseNumber = ($Plan.Phase_Suivante -replace '\D','')
    $fileName = "ArianeV4_Structure_Phase$phaseNumber.txt"
    $filePath = Join-Path $DocsDir $fileName

    $content = @"
ðŸ§  Cahier des charges â€“ Phase $phaseNumber â€“ Auto-Expansion Planner
ðŸ“… Date de gÃ©nÃ©ration : $($Plan.Date)

ðŸŽ¯ Objectif global
$($Plan.Objectif_Global)

ðŸ§© Modules ajoutÃ©s
$($Plan.Modules_Ajoutes -join "`n")

ðŸ› ï¸ Modules modifiÃ©s
$($Plan.Modules_Modifies -join "`n")

âŒ Modules supprimÃ©s
$($Plan.Modules_Supprimes -join "`n")

ðŸ“¦ Ã‰tat : $($Plan.Etat)
"@

    $content | Out-File $filePath -Encoding utf8
    Write-PlanLog "âœ… Fichier $fileName gÃ©nÃ©rÃ© automatiquement."
    Write-Host "âœ… Nouveau fichier de phase gÃ©nÃ©rÃ© : $fileName" -ForegroundColor Green
}

# ====================================================================
# 5ï¸âƒ£ Cycle complet
# ====================================================================
function Invoke-AutoExpansionPlanner {
    Write-Host "`nðŸ§± Lancement du cycle Auto-Expansion Planner..." -ForegroundColor Cyan
    Write-PlanLog "=== DÃ©but Auto-Expansion Planner ==="

    $plan = Generate-NextEvolutionPlan
    if ($plan) {
        Generate-PhaseFile -Plan $plan
        Write-PlanLog "âœ… Cycle Auto-Expansion terminÃ©."
        Write-Host "âœ… Nouveau plan et fichier gÃ©nÃ©rÃ©s avec succÃ¨s." -ForegroundColor Green
    } else {
        Write-PlanLog "âš ï¸ Aucun plan gÃ©nÃ©rÃ©."
        Write-Host "âš ï¸ Aucun changement Ã  planifier." -ForegroundColor Yellow
    }
}

# ====================================================================
# ðŸ”š Exports publics
# ====================================================================
Export-ModuleMember -Function `
    Get-EvolutionChanges, `
    Get-NextPhaseNumber, `
    Generate-NextEvolutionPlan, `
    Generate-PhaseFile, `
    Invoke-AutoExpansionPlanner

Write-Host "ðŸ§± Module Athena.AutoExpansionPlanner.psm1 chargÃ© (v1.0-Planning-Core)." -ForegroundColor Cyan
Write-PlanLog "Module AutoExpansionPlanner v1.0 chargÃ©."



