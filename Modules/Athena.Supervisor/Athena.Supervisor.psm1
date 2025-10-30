# ====================================================================
# ðŸ›°ï¸ Athena.Supervisor.psm1
# Phase 9 â€“ Supervision autonome du systÃ¨me Ariane/Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleRoot
$LogsDir     = Join-Path $RootDir "Logs"
$ModulesDir  = Join-Path $RootDir "Modules"
$MemoryDir   = Join-Path $RootDir "Memory"
$ReportFile  = Join-Path $LogsDir "AthenaReport.log"
$RecommandationsFile = Join-Path $RootDir "Recommandations.json"
$LogFile     = Join-Path $LogsDir "AthenaSupervisor.log"

function Write-SupervisorLog {
    param([string]$Msg, [string]$Level = "INFO")
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$time][$Level] $Msg"
}

function Invoke-AthenaSupervisor {
    Write-Host "`nðŸ›°ï¸ VÃ©rification systÃ¨me Athena en cours..." -ForegroundColor Cyan
    Write-SupervisorLog "DÃ©but de supervision Athena."

    # 1ï¸âƒ£ VÃ©rifier les modules essentiels
    $expectedModules = @(
        "Athena.Cognition.psm1", "Athena.SelfRepair.psm1", "Athena.Learning.psm1",
        "Athena.GlobalReport.psm1", "Athena.AutoPlanner.psm1"
    )

    $missingModules = @()
    foreach ($mod in $expectedModules) {
        $path = Join-Path $ModulesDir $mod
        if (!(Test-Path $path)) {
            $missingModules += $mod
            Write-SupervisorLog "Module manquant : $mod" "WARN"
        }
    }

    if ((@($missingModules).Count) -gt 0) {
        Write-Host "âš ï¸ Modules manquants dÃ©tectÃ©s : $($missingModules -join ', ')" -ForegroundColor Yellow
        Write-SupervisorLog "DÃ©clenchement du module SelfRepair." "ACTION"

        try {
            Import-Module (Join-Path $ModulesDir "Athena.SelfRepair.psm1") -Force -Global
            Invoke-Expression "Invoke-AthenaSelfRepair"
        } catch {
            Write-SupervisorLog "Erreur lors du dÃ©clenchement de SelfRepair : $_" "ERROR"
        }
    } else {
        Write-Host "âœ… Tous les modules essentiels sont prÃ©sents." -ForegroundColor Green
    }

    # 2ï¸âƒ£ VÃ©rifier le score global du dernier cycle
    if (Test-Path $ReportFile) {
        $content = Get-Content $ReportFile -Raw
        if ($content -match 'Score global : (\d+)%') {
            $score = [int]$matches[1]
            Write-SupervisorLog "Score global prÃ©cÃ©dent : $score%"
            if ($score -lt 50) {
                Write-Host "âš ï¸ Score faible dÃ©tectÃ© ($score%), planification dâ€™un correctif." -ForegroundColor Yellow
                Import-Module (Join-Path $ModulesDir "Athena.AutoPlanner.psm1") -Force -Global
                Invoke-Expression "Invoke-AthenaAutoPlanner -Mode 'correctif'"
            } else {
                Write-Host "ðŸ“ˆ Score prÃ©cÃ©dent satisfaisant : $score%" -ForegroundColor Green
            }
        }
    }

    # 3ï¸âƒ£ VÃ©rifier la durÃ©e du dernier cycle (si prÃ©sent dans le log)
    if (Test-Path $ReportFile) {
        $lines = Get-Content $ReportFile
        $durations = $lines | Select-String -Pattern "DurÃ©e totale : (\d+m \d+s)"
        if ($durations) {
            Write-SupervisorLog "DurÃ©e prÃ©cÃ©dente : $($durations.Matches[0].Groups[1].Value)"
        }
    }

    # 4ï¸âƒ£ Journalisation finale
    Write-SupervisorLog "Fin de supervision Athena."
    Write-Host "ðŸ›°ï¸ Supervision terminÃ©e â€“ tout est prÃªt pour le cycle du jour." -ForegroundColor Cyan
}
Export-ModuleMember -Function Invoke-AthenaSupervisor




