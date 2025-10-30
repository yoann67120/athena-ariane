# ====================================================================
# ðŸ¤– Athena.AutoCycle.psm1 â€“ Cycle auto-rÃ©gÃ©nÃ©rant (Phase 8)
# ====================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$LogsDir    = Join-Path $RootDir "Logs"
$LogFile    = Join-Path $LogsDir "AthenaDaily.log"
$NextPlan   = Join-Path $RootDir "Data\GPT\NextPlan.json"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-AthenaLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
    Write-Host $Msg
}

function Invoke-AthenaAutoCycle {
    Write-Host "`nðŸš€ DÃ©marrage du cycle Athena auto-rÃ©gÃ©nÃ©rant..." -ForegroundColor Cyan
    Write-AthenaLog "=== Nouveau cycle journalier lancÃ© ==="

    $modules = @(
        "Athena.Cognition",
        "Athena.SelfRepair",
        "Athena.Learning",
        "Memory.Analytics",
        "Athena.GlobalReport",
        "Athena.AutoPlanner"
    )

    foreach ($m in $modules) {
        $path = Join-Path $RootDir "Modules\$m.psm1"
        if (Test-Path $path) {
            try {
                Import-Module $path -Force -Global
                Write-AthenaLog "âœ… Module $m chargÃ©"
            } catch {
                Write-AthenaLog "âš ï¸ Erreur import $m : $_" "WARN"
            }
        } else {
            Write-AthenaLog "âŒ Module $m manquant" "ERROR"
        }
    }

    # Lecture du score global du rapport
$Score = 0
$ReportFile = Join-Path $LogsDir "AthenaReport.log"
if (Test-Path $ReportFile) {
    $line = Select-String -Path $ReportFile -Pattern "Score global" | Select-Object -Last 1
    if ($line) {
        $value = $line.ToString() -replace '[^\d]', ''
        if ($value.Length -gt 3) { $value = $value.Substring(0,2) }  # coupe le doublon "4646"
        $Score = [int]$value
    }
}

Write-AthenaLog "ðŸ“Š Score global du jour : $Score %"

if ($Score -lt 70) {
    Write-AthenaLog "ðŸ” Score faible, planification dâ€™un cycle correctif demain." "WARN"
    $NextPlanData = @{
        action = "ScheduleNextCycle"
        score  = $Score
        date   = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
    } | ConvertTo-Json -Depth 3
    $NextPlanData | Out-File -FilePath $NextPlan -Encoding utf8 -Force
} else {
    Write-AthenaLog "ðŸŒ… Score satisfaisant, maintien du rythme normal."
}

Write-AthenaLog "=== Fin du cycle Athena ===`n"

# DÃ©clenche la notification Cockpit si disponible
$NotifyPath = Join-Path $RootDir "Modules\Cockpit.Notify.psm1"
if (Test-Path $NotifyPath) {
    Import-Module $NotifyPath -Force -Global
    Invoke-CockpitNotify
}

Write-Host "`nðŸŒ… Cycle Athena journalier terminÃ©."
}
Export-ModuleMember -Function Invoke-AthenaAutoCycle




