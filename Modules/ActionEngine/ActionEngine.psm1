# ====================================================================
# âš™ï¸ ActionEngine.psm1 â€“ ExÃ©cution intelligente des plans dâ€™action
# Version : v1.7-AutoResolver (compatible GPTFusion)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir "Logs"
$PlansDir  = Join-Path $RootDir "Data\Plans"
$LogFile   = Join-Path $LogsDir "ActionEngine.log"

foreach ($dir in @($LogsDir,$PlansDir)) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

function Write-ActionLog {
    param([string]$Msg,[string]$Level="INFO")
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level] $Msg"
}

# --------------------------------------------------------------------
# ðŸ”§ ExÃ©cute un plan dâ€™action JSON ou un nom court
# --------------------------------------------------------------------
function Invoke-ActionPlan {
    param([Parameter(Mandatory)][string]$Plan)

    Write-Host "`nâš™ï¸ ExÃ©cution du plan : $Plan" -ForegroundColor Cyan
    $Path = if (Test-Path $Plan) { $Plan } else { Join-Path $PlansDir "$Plan.json" }

    if (!(Test-Path $Path)) {
        Write-Warning "âŒ Plan introuvable : $Path"
        Write-ActionLog "Plan introuvable : $Path" "WARN"
        return
    }

    try {
        $Data = Get-Content $Path -Raw | ConvertFrom-Json
        $Steps = $Data.Steps
        if (-not $Steps) { $Steps = $Data.recommandations }

        foreach ($step in $Steps) {
            switch -Regex ($step.Action) {
                "Import-Module" {
                    Import-Module $step.Target -Force -Global
                    Write-Host "ðŸ“¦ Import : $($step.Target)" -ForegroundColor Cyan
                    Write-ActionLog "Import module $($step.Target)"
                }
                "Invoke-Expression" {
                    Invoke-Expression $step.Target
                    Write-Host "âš™ï¸  ExÃ©cution : $($step.Target)" -ForegroundColor DarkCyan
                }
                "Write-Host" {
                    Write-Host $step.Message -ForegroundColor Gray
                }
                default {
                    Write-Warning "âš ï¸ Action inconnue : $($step.Action)"
                }
            }
        }
        Write-Host "âœ… Plan exÃ©cutÃ© avec succÃ¨s.`n" -ForegroundColor Green
        Write-ActionLog "Plan exÃ©cutÃ© : $Path"
    }
    catch {
        Write-Warning "âš ï¸ Erreur pendant le plan : $_"
        Write-ActionLog "Erreur : $($_.Exception.Message)" "ERROR"
    }
}

Export-ModuleMember -Function Invoke-ActionPlan
Write-Host "âœ… ActionEngine chargÃ© (v1.7 AutoResolver â€“ compatible GPTFusion)." -ForegroundColor Cyan

















