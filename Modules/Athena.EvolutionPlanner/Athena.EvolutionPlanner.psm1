# ====================================================================
# ðŸ”® Athena.EvolutionPlanner.psm1 (v1.0-Adaptive-Planning-Engine)
# Objectif : GÃ©nÃ©rer un plan d'Ã©volution automatique basÃ© sur la stabilitÃ©,
#             les anomalies dÃ©tectÃ©es et la rÃ©flexion cognitive dâ€™Athena.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === Dossiers ===
$ModuleRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ModuleRoot
$MemoryDir   = Join-Path $ProjectRoot 'Memory'
$LogsDir     = Join-Path $ProjectRoot 'Logs'

$EvolutionPlan   = Join-Path $MemoryDir 'EvolutionPlan.json'
$ReflectionFile  = Join-Path $MemoryDir 'ReflectionSummary.json'
$RoadmapFile     = Join-Path $MemoryDir 'EvolutionRoadmap.json'
$PlannerLog      = Join-Path $LogsDir 'EvolutionPlanner.log'

if (!(Test-Path $LogsDir))  { New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null }
if (!(Test-Path $MemoryDir)){ New-Item -ItemType Directory -Force -Path $MemoryDir | Out-Null }

# ====================================================================
# ðŸ”¹ Lecture des sources (AutoEvolution + Reflection)
# ====================================================================
function Get-PlanningData {
    $plan = @()
    $reflexions = @()

    if (Test-Path $EvolutionPlan) {
        try {
            $json = Get-Content $EvolutionPlan -Raw | ConvertFrom-Json
            if ($json.Modules_To_Patch) { $plan = $json.Modules_To_Patch }
        } catch {}
    }

    if (Test-Path $ReflectionFile) {
        try {
            $json = Get-Content $ReflectionFile -Raw | ConvertFrom-Json
            if ((@($json).Count) -gt 0) { $reflexions = $json | Select-Object -Last 3 }
        } catch {}
    }

    return [PSCustomObject]@{
        Technical = $plan
        Cognitive = $reflexions
    }
}

# ====================================================================
# ðŸ”¹ Calcul du score de prioritÃ©
# ====================================================================
function Compute-PriorityScore {
    param([string]$Reason, [int]$Count)

    $base = switch -regex ($Reason) {
        'corrompu' { 95 }
        'ancien'   { 80 }
        'alerte'   { 70 }
        default    { 60 }
    }
    $boost = [math]::Min($Count * 5, 20)
    return [math]::Min($base + $boost, 100)
}

# ====================================================================
# ðŸ”¹ GÃ©nÃ©ration du plan d'Ã©volution
# ====================================================================
function Generate-EvolutionRoadmap {
    param([object]$Data)

    $planList = @()
    $day = 1

    foreach ($mod in $Data.Technical) {
        $count = (Get-Random -Minimum 1 -Maximum 4)
        $score = Compute-PriorityScore -Reason $mod.Reason -Count $count
        $planList += [PSCustomObject]@{
            Jour    = $day
            Module  = $mod.Name
            Action  = "RÃ©vision ou Patch"
            Score   = $score
        }
        $day++
    }

    foreach ($cog in $Data.Cognitive) {
        $text = $cog.Reflection
        if ($text -match 'mÃ©moire|cognition|harmonie') {
            $planList += [PSCustomObject]@{
                Jour    = $day
                Module  = "Athena.Core"
                Action  = "Optimisation cognitive"
                Score   = [math]::Round((Get-Random -Minimum 70 -Maximum 95),2)
            }
            $day++
        }
    }

    $planList = $planList | Sort-Object -Property Score -Descending
    $planList | ConvertTo-Json -Depth 4 | Out-File $RoadmapFile -Encoding utf8

    Add-Content -Path $PlannerLog -Value "===== Nouveau plan gÃ©nÃ©rÃ© le $(Get-Date -Format 'u') ====="
    foreach ($p in $planList) {
        Add-Content -Path $PlannerLog -Value ("Jour {0}: {1} â†’ {2} (Score: {3})" -f $p.Jour,$p.Module,$p.Action,$p.Score)
    }
    Add-Content -Path $PlannerLog -Value "===========================================================`n"

    return $planList
}

# ====================================================================
# ðŸ”¹ Fonction principale
# ====================================================================
function Invoke-AthenaEvolutionPlanner {
    Write-Host "`nðŸ”® Phase 17 â€“ Planification adaptative de lâ€™Ã©volution..." -ForegroundColor Cyan

    $data = Get-PlanningData
    if ($data.Technical.Count -eq 0 -and $data.Cognitive.Count -eq 0) {
        Write-Host "âš ï¸ Aucune donnÃ©e Ã  planifier (EvolutionPlan et Reflection vides)." -ForegroundColor Yellow
        return
    }

    $roadmap = Generate-EvolutionRoadmap -Data $data
    Write-Host "âœ… Plan dâ€™Ã©volution gÃ©nÃ©rÃ© : $((@($roadmap).Count)) actions planifiÃ©es." -ForegroundColor Green
    Write-Host "ðŸ“„ DÃ©tails disponibles dans Memory\\EvolutionRoadmap.json" -ForegroundColor DarkGray
}

Export-ModuleMember -Function Invoke-AthenaEvolutionPlanner




