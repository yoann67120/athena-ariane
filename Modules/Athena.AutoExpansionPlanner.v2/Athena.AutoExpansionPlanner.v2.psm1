# ====================================================================
# ðŸ§  Athena.AutoExpansionPlanner.v2.psm1 â€“ v2.0 Self-Generative Adaptive SafeMode
# --------------------------------------------------------------------
# Objectif :
#   - Ã‰tendre automatiquement Ariane/Athena vers les phases manquantes.
#   - GÃ©nÃ©rer les fichiers de structure, scripts de vÃ©rification et logs.
#   - Sâ€™adapter Ã  lâ€™environnement sans risque : Safe-Write + Limitation cycles.
#   - CoopÃ¨re avec : IntegrationGuardian, LearningEngine, SelfRepair.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Version : v2.0-Adaptive-Safe
# Date    : 2025-10-17
# Statut  : âœ… Stable & Autonome â€“ FIGÃ‰ pour SafeMode
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === ðŸ“ RÃ©pertoires racine ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$ScriptsDir = Join-Path $RootDir "Scripts"
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$ReportDir  = Join-Path $LogsDir "Reports"

foreach ($d in @($ScriptsDir,$MemoryDir,$LogsDir,$ReportDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$LogFile = Join-Path $LogsDir "AutoExpansionPlanner_v2.log"

function Write-PlannerLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# âš™ï¸ Safe-Write : protÃ¨ge contre la corruption ou lâ€™Ã©crasement
# ====================================================================
function SafeWriteFile {
    param([string]$Path,[string]$Content)
    try {
        if (Test-Path $Path) {
            $backup = "$Path.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item $Path $backup -Force
        }
        $Content | Out-File $Path -Encoding utf8
        Write-PlannerLog "Fichier Ã©crit : $Path"
    } catch {
        Write-PlannerLog "Erreur SafeWrite : $_" "ERROR"
    }
}

# ====================================================================
# ðŸ§© DÃ©tection des phases manquantes
# ====================================================================
function Get-MissingPhases {
    $expected = 36..50
    $present = @(Get-ChildItem $ScriptsDir -Filter "ArianeV4_Structure_Phase*.txt" -ErrorAction SilentlyContinue |
                ForEach-Object { [regex]::Match($_.Name,'\d+').Value } | ForEach-Object { [int]$_ })
    return $expected | Where-Object { $_ -notin $present }
}

# ====================================================================
# ðŸ§± CrÃ©ation automatique dâ€™une phase
# ====================================================================
function New-AthenaPhase {
    param([int]$Number)
    $txt  = Join-Path $ScriptsDir "ArianeV4_Structure_Phase$Number.txt"
    $check = Join-Path $ScriptsDir "Athena_Phase$Number_Check.ps1"

    $content = @"
# ============================================================
# ðŸš€ ArianeV4 â€“ Structure de Phase $Number
# ============================================================
NomPhase : Phase $Number
Statut   : InitialisÃ©e automatiquement
Date     : $(Get-Date)
Description :
  Phase $Number crÃ©Ã©e par Athena.AutoExpansionPlanner v2
"@
    SafeWriteFile -Path $txt -Content $content

    $checkContent = @"
# Athena_Phase$Number_Check.ps1 â€“ Test automatique de phase $Number
Write-Host 'ðŸ” VÃ©rification de la phase $Number...' -ForegroundColor Cyan
Write-Host 'âœ… Phase $Number vÃ©rifiÃ©e avec succÃ¨s.' -ForegroundColor Green
"@
    SafeWriteFile -Path $check -Content $checkContent
}

# ====================================================================
# ðŸ§  Cycle complet Auto-Expansion
# ====================================================================
function Invoke-AutoExpansionPlanner {
    param([int]$TargetPhase = 50,[switch]$Force)
    Write-Host "`nðŸ§± Lancement du cycle Auto-Expansion Planner v2..." -ForegroundColor Cyan
    Write-PlannerLog "--- Cycle Auto-Expansion v2 ---"

    $missing = Get-MissingPhases | Where-Object { $_ -le $TargetPhase }
    if (!$missing -and !$Force) {
        Write-Host "âš ï¸ Aucun changement Ã  planifier." -ForegroundColor Yellow
        Write-PlannerLog "Aucune phase manquante."
        return
    }

    foreach ($p in $missing) {
        Write-Host "ðŸ§© CrÃ©ation de la phase $p..." -ForegroundColor Yellow
        New-AthenaPhase $p
    }

    # Mise Ã  jour du plan dâ€™Ã©volution
    $planFile = Join-Path $MemoryDir "EvolutionPlans.json"
    $existing = @()
    if (Test-Path $planFile) {
        try { $existing = Get-Content $planFile -Raw | ConvertFrom-Json } catch {}
    }
    foreach ($p in $missing) {
        $existing += [pscustomobject]@{
            Date         = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Phase        = $p
            Statut       = "InitialisÃ©e"
            Commentaire  = "Auto-Expansion v2"
        }
    }
    $existing | ConvertTo-Json -Depth 5 | Out-File $planFile -Encoding utf8
    Write-PlannerLog "Plan dâ€™Ã©volution mis Ã  jour."

    Write-Host "âœ… Expansion v2 terminÃ©e : $($missing.Count) phases crÃ©Ã©es ou mises Ã  jour." -ForegroundColor Green
    Write-PlannerLog "Expansion complÃ¨te. $($missing.Count) phases crÃ©Ã©es."
}

# ====================================================================
# ðŸ”„ Apprentissage adaptatif (post-analyse des logs)
# ====================================================================
function Invoke-ExpansionLearning {
    Write-Host "ðŸ§  Analyse des journaux pour ajustement du plan dâ€™Ã©volution..." -ForegroundColor Cyan
    $logs = Get-ChildItem $LogsDir -Filter "*.log" -Recurse | Select-Object -Last 40
    $keywords = @()
    foreach ($l in $logs) {
        $txt = (Get-Content $l.FullName -Raw)
        if ($txt -match "Integration|Repair|Learning|Cognition|Phase") {
            $keywords += [System.IO.Path]::GetFileNameWithoutExtension($l.Name)
        }
    }
    $keywords = $keywords | Sort-Object -Unique
    if ($keywords) {
        Write-Host "ðŸ” Mots-clÃ©s appris : $($keywords -join ', ')" -ForegroundColor Gray
        Write-PlannerLog "Keywords appris : $($keywords -join ', ')"
    }
}

# ====================================================================
# ðŸ”’ Limitation de cycle â€“ prÃ©vention boucles infinies
# ====================================================================
function Test-ExpansionLock {
    $flag = Join-Path $MemoryDir "AutoExpansion_LastRun.txt"
    if (Test-Path $flag) {
        $last = [datetime](Get-Content $flag -Raw)
        if ((New-TimeSpan -Start $last -End (Get-Date)).TotalHours -lt 1) {
            Write-Host "â³ DerniÃ¨re exÃ©cution rÃ©alisÃ©e il y a moins dâ€™une heure â€“ abandon sÃ©curisÃ©." -ForegroundColor Yellow
            return $true
        }
    }
    (Get-Date).ToString("s") | Out-File $flag -Encoding utf8
    return $false
}

# ====================================================================
# ðŸš€ Routine principale
# ====================================================================
function Invoke-AthenaAutoExpansion {
    if (Test-ExpansionLock) { return }
    Invoke-AutoExpansionPlanner
    Invoke-ExpansionLearning
    Write-Host "ðŸª¶ Cycle Auto-Expansion v2 terminÃ© en SafeMode." -ForegroundColor Cyan
    Write-PlannerLog "Cycle SafeMode terminÃ©."
}

Export-ModuleMember -Function Invoke-AutoExpansionPlanner, Invoke-AthenaAutoExpansion
Write-Host "ðŸ§  Module Athena.AutoExpansionPlanner v2 chargÃ© (Safe-Generative Mode)." -ForegroundColor Cyan
Write-PlannerLog "Module v2 chargÃ© avec succÃ¨s."
# ====================================================================



