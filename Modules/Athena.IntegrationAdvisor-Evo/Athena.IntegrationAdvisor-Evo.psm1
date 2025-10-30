# ====================================================================
# ðŸ§  Athena.IntegrationAdvisor-Evo.psm1 â€“ v1.2-Evolution-AutoContext
# --------------------------------------------------------------------
# Objectif :
#   Version Ã©volutive du moteur dâ€™analyse open-source dâ€™Athena.
#   Compatible avec OpenSourceRegistry.json hiÃ©rarchique (v1.2+)
#   + Ajout du scoring contextuel et dâ€™un mode silencieux.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ====================================================================
# ðŸ“ RÃ©pertoires et fichiers
# ====================================================================
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ConfigDir  = Join-Path $RootDir "Config"
$LogFile    = Join-Path $LogsDir  "IntegrationAdvisor.log"
$PlanFile   = Join-Path $MemoryDir "EvolutionPlans.json"
$Registry   = Join-Path $ConfigDir "OpenSourceRegistry.json"

foreach ($p in @($LogsDir,$MemoryDir,$ConfigDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# ====================================================================
# âœï¸ Journal interne
# ====================================================================
function Write-AdvisorLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# 1ï¸âƒ£ DÃ©tection des besoins Ã  partir du contexte
# ====================================================================
function Scan-AthenaNeeds {
    param([string]$Context)
    Write-AdvisorLog "Analyse du contexte : $Context"

    $needs = @()
    if ($Context -match 'workflow|automatisation|tÃ¢che') { $needs += 'automation' }
    if ($Context -match 'base|donnÃ©e|stockage|sql|json')  { $needs += 'database' }
    if ($Context -match 'ia|intelligence|local|gpt|llm')  { $needs += 'local-llm' }
    if ($Context -match 'image|gÃ©nÃ©ration|art')           { $needs += 'ai-image' }
    if ($Context -match 'voix|audio|vocale|speech')       { $needs += 'voice' }
    if ($Context -match 'git|code|version|repository')    { $needs += 'repository' }
    if ($Context -match 'supervision|dashboard|mÃ©trique') { $needs += 'monitoring' }
    if ($Context -match 'cloud|stockage|fichier')         { $needs += 'storage' }

    if ($needs.Count -eq 0) { Write-AdvisorLog "Aucun besoin explicite dÃ©tectÃ©." }
    return $needs | Sort-Object -Unique
}

# ====================================================================
# 2ï¸âƒ£ Recherche hiÃ©rarchique de solutions open-source + scoring
# ====================================================================
function Search-OpenSourceSolutions {
    param([array]$Needs)
    if (!(Test-Path $Registry)) {
        Write-AdvisorLog "âŒ Registre $Registry introuvable."
        return @()
    }
    $reg = Get-Content $Registry -Raw | ConvertFrom-Json
    $found = @()

    foreach ($section in $reg.PSObject.Properties.Name) {
        foreach ($tool in $reg.$section.PSObject.Properties.Name) {
            $entry = $reg.$section.$tool
            foreach ($need in $Needs) {
                $matchCount = ($entry.keywords | Where-Object { $_ -match $need }).Count
                if ($entry.type -eq $need -or $matchCount -gt 0) {
                    $score = [math]::Min(100, ($matchCount * 20) + (if ($entry.type -eq $need) { 40 } else { 0 }))
                    $found += [pscustomobject]@{
                        Section = $section
                        Tool    = $tool
                        Type    = $entry.type
                        Score   = $score
                        Use     = $entry.use
                        Link    = $entry.link
                    }
                }
            }
        }
    }

    $sorted = $found | Sort-Object -Property Score -Descending
    Write-AdvisorLog "Solutions trouvÃ©es : $($sorted.Count)"
    return $sorted
}

# ====================================================================
# 3ï¸âƒ£ Proposition dâ€™intÃ©gration
# ====================================================================
function Propose-IntegrationPlan {
    param([array]$Solutions)
    if (-not $Solutions -or (($Solutions | Measure-Object).Count -eq 0)) {
        Write-AdvisorLog "Aucune intÃ©gration trouvÃ©e."
        return "Aucune intÃ©gration trouvÃ©e."
    }

    $msg = "ðŸ”— IntÃ©grations proposÃ©es :`n"
    foreach ($s in $Solutions | Select-Object -First 5) {
        $msg += "â†’ [$($s.Score)%] $($s.Tool) : $($s.Use)`n"
    }

    Write-AdvisorLog $msg
    return $msg
}

# ====================================================================
# 4ï¸âƒ£ Ajout automatique dans EvolutionPlans.json
# ====================================================================
function Register-IntegrationInPlan {
    param([array]$Solutions,[string]$Context)
    Write-AdvisorLog "Ajout des intÃ©grations au plan."

    $plans = @()
    if (Test-Path $PlanFile) {
        try { $plans = Get-Content $PlanFile -Raw | ConvertFrom-Json } catch { $plans = @() }
    }

    foreach ($s in $Solutions | Select-Object -First 5) {
        $plans += [pscustomobject]@{
            Date        = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Context     = $Context
            Integration = $s.Tool
            Type        = $s.Type
            Score       = $s.Score
            Statut      = "ProposÃ©"
        }
    }

    $plans | ConvertTo-Json -Depth 4 | Out-File $PlanFile -Encoding utf8
    Write-AdvisorLog "Plan dâ€™Ã©volution mis Ã  jour ($($Solutions.Count) entrÃ©es)."
}

# ====================================================================
# 5ï¸âƒ£ Cycle complet dâ€™analyse
# ====================================================================
function Invoke-AthenaIntegrationAdvisor {
    param(
        [string]$Context = "analyse gÃ©nÃ©rique",
        [switch]$Silent
    )

    Write-AdvisorLog "Cycle dâ€™analyse lancÃ© pour contexte : $Context"
    if (-not $Silent) { Write-Host "`nðŸ§© Lancement du moteur dâ€™intÃ©gration..." -ForegroundColor Cyan }

    $needs   = Scan-AthenaNeeds -Context $Context
    $sol     = Search-OpenSourceSolutions -Needs $needs
    $summary = Propose-IntegrationPlan -Solutions $sol

    if ($sol -and (($sol | Measure-Object).Count -gt 0)) {
        Register-IntegrationInPlan -Solutions $sol -Context $Context

        if (-not $Silent) {
            $Notify = Join-Path $ModuleRoot "Cockpit.Notify.psm1"
            $Voice  = Join-Path $ModuleRoot "Voice.psm1"
            if (Test-Path $Notify) {
                Import-Module $Notify -Force -Global
                if (Get-Command Invoke-CockpitNotify -ErrorAction SilentlyContinue) {
                    Invoke-CockpitNotify -Message $summary -Tone "info" -Color "blue"
                }
            }
            if (Test-Path $Voice) {
                Import-Module $Voice -Force -Global
                if (Get-Command Speak-Athena -ErrorAction SilentlyContinue) {
                    Speak-Athena ($summary -replace 'ðŸ”—','').Trim()
                }
            }
        }

        if (-not $Silent) {
            Write-Host "âœ… $((($sol | Measure-Object).Count)) intÃ©grations proposÃ©es et planifiÃ©es." -ForegroundColor Green
        }
        Write-AdvisorLog "âœ… IntÃ©grations planifiÃ©es avec succÃ¨s."
    } else {
        if (-not $Silent) { Write-Host "âš ï¸ Aucune intÃ©gration trouvÃ©e." -ForegroundColor Yellow }
        Write-AdvisorLog "âš ï¸ Aucune intÃ©gration trouvÃ©e."
    }
}

# ====================================================================
# ðŸ”š Export public
# ====================================================================
Export-ModuleMember -Function `
    Invoke-AthenaIntegrationAdvisor, `
    Scan-AthenaNeeds, `
    Search-OpenSourceSolutions, `
    Propose-IntegrationPlan, `
    Register-IntegrationInPlan

Write-Host "ðŸ§  Module Athena.IntegrationAdvisor-Evo.psm1 chargÃ© (v1.2-Evolution)." -ForegroundColor Cyan
Write-AdvisorLog "Module Evo v1.2 chargÃ© â€“ lecture hiÃ©rarchique + scoring actif."



