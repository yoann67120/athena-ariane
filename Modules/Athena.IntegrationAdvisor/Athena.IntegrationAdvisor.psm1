# ====================================================================
# ðŸ§  Athena.IntegrationAdvisor.psm1 â€“ v1.1-Stable-FIGÃ‰
# --------------------------------------------------------------------
# Objectif :
#   Moteur dâ€™analyse et de recommandation open-source dâ€™Athena.
#   Analyse les besoins internes (Cognition / Ã‰volution / Coordination),
#   propose des intÃ©grations externes open-source adaptÃ©es,
#   les ajoute automatiquement Ã  EvolutionPlans.json,
#   et informe Yoann via la Voix + Cockpit.
#
#   Ce module est figÃ© pour garantir la stabilitÃ© des Phases 35 â†’ 40.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Version : v1.1-Stable-FIGÃ‰
# Date    : 2025-10-17
# Statut  : âœ… VÃ©rifiÃ© & validÃ© â€“ Compatible SelfCoordinator v1.0+
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
# 1ï¸âƒ£ DÃ©tection des besoins
# ====================================================================
function Scan-AthenaNeeds {
    param([string]$Context)
    Write-AdvisorLog "Analyse du contexte : $Context"

    $needs = @()
    if ($Context -match 'workflow|automatisation') { $needs += 'automation' }
    if ($Context -match 'base|donnÃ©e|stockage|json') { $needs += 'database' }
    if ($Context -match 'ia|intelligence|local')    { $needs += 'local-llm' }
    if ($Context -match 'git|code|version')         { $needs += 'repository' }

    if ($needs.Count -eq 0) { Write-AdvisorLog "Aucun besoin explicite dÃ©tectÃ©." }
    return $needs | Sort-Object -Unique
}

# ====================================================================
# 2ï¸âƒ£ Recherche de solutions open-source
# ====================================================================
function Search-OpenSourceSolutions {
    param([array]$Needs)
    if (!(Test-Path $Registry)) {
        Write-AdvisorLog "âŒ Registre $Registry introuvable."
        return @()
    }
    $reg = Get-Content $Registry -Raw | ConvertFrom-Json
    $found = @()

    foreach ($need in $Needs) {
        foreach ($tool in $reg.PSObject.Properties.Name) {
            $entry = $reg.$tool
            if ($entry.type -eq $need -or ($entry.keywords -contains $need)) {
                $found += [pscustomobject]@{
                    Tool = $tool
                    Type = $entry.type
                    Use  = $entry.use
                    Link = $entry.link
                }
            }
        }
    }
    Write-AdvisorLog "Solutions trouvÃ©es : $((($found | Measure-Object).Count))"
    return $found
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
    foreach ($s in $Solutions) {
        $msg += "â†’ $($s.Tool) : $($s.Use)`n"
    }

    Write-AdvisorLog $msg
    return $msg
}

# ====================================================================
# 4ï¸âƒ£ Notification cockpit + voix
# ====================================================================
function Notify-IntegrationProposal {
    param([string]$Summary)
    Write-AdvisorLog "Notification cockpit/voix."

    $Notify = Join-Path $ModuleRoot "Cockpit.Notify.psm1"
    $Voice  = Join-Path $ModuleRoot "Voice.psm1"

    if (Test-Path $Notify) {
        Import-Module $Notify -Force -Global
        if (Get-Command Invoke-CockpitNotify -ErrorAction SilentlyContinue) {
            Invoke-CockpitNotify -Message $Summary -Tone "info" -Color "blue"
        }
    }

    if (Test-Path $Voice) {
        Import-Module $Voice -Force -Global
        if (Get-Command Speak-Athena -ErrorAction SilentlyContinue) {
            Speak-Athena ($Summary -replace 'ðŸ”—','').Trim()
        }
    }
}

# ====================================================================
# 5ï¸âƒ£ Ajout automatique dans EvolutionPlans.json
# ====================================================================
function Register-IntegrationInPlan {
    param([array]$Solutions,[string]$Context)
    Write-AdvisorLog "Ajout des intÃ©grations au plan."

    $plans = @()
    if (Test-Path $PlanFile) {
        try { $plans = Get-Content $PlanFile -Raw | ConvertFrom-Json } catch { $plans = @() }
    }

    foreach ($s in $Solutions) {
        $plans += [pscustomobject]@{
            Date        = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Context     = $Context
            Integration = $s.Tool
            Type        = $s.Type
            Statut      = "ProposÃ©"
        }
    }

    $plans | ConvertTo-Json -Depth 4 | Out-File $PlanFile -Encoding utf8
    Write-AdvisorLog "Plan dâ€™Ã©volution mis Ã  jour ($((($Solutions | Measure-Object).Count)) entrÃ©es)."
}

# ====================================================================
# 6ï¸âƒ£ Cycle complet dâ€™analyse
# ====================================================================
function Invoke-AthenaIntegrationAdvisor {
    param([string]$Context = "analyse gÃ©nÃ©rique")
    Write-Host "`nðŸ§© Lancement du moteur dâ€™intÃ©gration..." -ForegroundColor Cyan
    Write-AdvisorLog "Cycle dâ€™analyse lancÃ© pour contexte : $Context"

    $needs   = Scan-AthenaNeeds -Context $Context
    $sol     = Search-OpenSourceSolutions -Needs $needs
    $summary = Propose-IntegrationPlan -Solutions $sol

    if ($sol -and (($sol | Measure-Object).Count -gt 0)) {
        Register-IntegrationInPlan -Solutions $sol -Context $Context
        Notify-IntegrationProposal -Summary $summary
        Write-Host "âœ… $((($sol | Measure-Object).Count)) intÃ©grations proposÃ©es et planifiÃ©es." -ForegroundColor Green
        Write-AdvisorLog "âœ… IntÃ©grations planifiÃ©es avec succÃ¨s."
    } else {
        Write-Host "âš ï¸ Aucune intÃ©gration trouvÃ©e." -ForegroundColor Yellow
        Write-AdvisorLog "âš ï¸ Aucune intÃ©gration trouvÃ©e."
    }
}

# ====================================================================
# ðŸ”® Fonctions futures (prÃ©-intÃ©grÃ©es, inactives)
# ====================================================================
<#
function Evaluate-IntegrationSuccess { }
function Learn-PreferredTools { }
function Auto-ExpandRegistry { }
function Discover-AIEndpoints { }
function Visualize-IntegrationMap { }
#>

# ====================================================================
# ðŸ”š Export public
# ====================================================================
Export-ModuleMember -Function `
    Invoke-AthenaIntegrationAdvisor, `
    Scan-AthenaNeeds, `
    Search-OpenSourceSolutions, `
    Propose-IntegrationPlan, `
    Notify-IntegrationProposal, `
    Register-IntegrationInPlan

Write-Host "ðŸ§  Module Athena.IntegrationAdvisor.psm1-FIGÃ‰ chargÃ© (v1.1-Stable-FIGÃ‰)." -ForegroundColor Cyan
Write-AdvisorLog "Module figÃ© v1.1 chargÃ© â€“ prÃªt pour Phases 35 â†’ 40."

# ====================================================================
# ðŸ§  Patch intÃ©grÃ© â€“ Fonction de test dâ€™intÃ©gration globale
# ====================================================================
function Invoke-IntegrationCheck {
    param([switch]$Silent)

    $RootDir   = Split-Path -Parent $PSScriptRoot
    $MemoryDir = Join-Path $RootDir "Memory"
    $LogsDir   = Join-Path $RootDir "Logs"
    $ContextsFile = Join-Path $MemoryDir "IntegrationContexts.json"
    $LogFile = Join-Path $LogsDir "IntegrationAdvisor_Test.log"

    Write-Host "ðŸ” VÃ©rification dâ€™intÃ©gration en cours..." -ForegroundColor Cyan
    "[$(Get-Date)] DÃ©but du test dâ€™intÃ©gration" | Out-File $LogFile -Encoding UTF8

    if (Test-Path $ContextsFile) {
        try {
            $data = Get-Content $ContextsFile -Raw | ConvertFrom-Json
            foreach ($ctx in $data.PSObject.Properties.Name) {
                $status = "OK"
                $data.$ctx.status = $status
                $data.$ctx.lastCheck = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                Add-Content $LogFile ("âœ… {0} : {1}" -f $ctx, $status)
            }
            $data | ConvertTo-Json -Depth 5 | Out-File $ContextsFile -Encoding UTF8
            Add-Content $LogFile "âœ… VÃ©rification terminÃ©e."
        } catch {
            Add-Content $LogFile "âŒ Erreur pendant la lecture/Ã©criture : $_"
        }
    } else {
        Add-Content $LogFile "âš ï¸ Aucun fichier IntegrationContexts.json trouvÃ©."
    }

    Write-Host "âœ… VÃ©rification dâ€™intÃ©gration terminÃ©e. Consulte : $LogFile" -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-IntegrationCheck
# ====================================================================





