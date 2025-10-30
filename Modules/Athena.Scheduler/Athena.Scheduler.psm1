# ====================================================================
# ðŸ•’ Athena.Scheduler.psm1 â€“ v1.2-Fix (Auto-Scheduler Stable)
# Description : crÃ©ation et supervision de la tÃ¢che planifiÃ©e Athena_NightlyBackup
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $ProjectDir "Logs"
$ScriptsDir = Join-Path $ProjectDir "Scripts"

if (!(Test-Path $LogsDir))   { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (!(Test-Path $ScriptsDir)) { New-Item -ItemType Directory -Path $ScriptsDir -Force | Out-Null }

$SchedulerLog = Join-Path $LogsDir "AthenaScheduler.log"

# --------------------------------------------------------------------
# ðŸ•’ CrÃ©ation / Mise Ã  jour de la tÃ¢che planifiÃ©e
# --------------------------------------------------------------------
function Register-AthenaTask {
    $taskName = "Athena_NightlyBackup"
    $script   = Join-Path $ScriptsDir "Athena_NightlyBackup.ps1"
    $pwsh     = (Get-Command pwsh).Source

    $action   = New-ScheduledTaskAction -Execute $pwsh -Argument "`"$script`""
    $trigger  = New-ScheduledTaskTrigger -Daily -At 03:30
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    $principal= New-ScheduledTaskPrincipal -UserId $env:USERNAME

    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
        Add-Content -Path $SchedulerLog -Value "[$(Get-Date -Format u)] âœ… TÃ¢che planifiÃ©e crÃ©Ã©e ou mise Ã  jour."
        Write-Host "âœ… TÃ¢che planifiÃ©e $taskName crÃ©Ã©e/mise Ã  jour." -ForegroundColor Green
    }
    catch {
        $msg = "[$(Get-Date -Format u)] âŒ Erreur crÃ©ation tÃ¢che : $($_.Exception.Message)"
        Add-Content -Path $SchedulerLog -Value $msg
        Write-Warning $msg
    }
}

# --------------------------------------------------------------------
# ðŸ” VÃ©rification du statut de la tÃ¢che
# --------------------------------------------------------------------
function Get-AthenaTaskStatus {
    try {
        $t = Get-ScheduledTask -TaskName "Athena_NightlyBackup" -ErrorAction Stop
        Add-Content -Path $SchedulerLog -Value "[$(Get-Date -Format u)] Statut actuel : $($t.State)"
        return $t.State
    }
    catch {
        Add-Content -Path $SchedulerLog -Value "[$(Get-Date -Format u)] âŒ TÃ¢che introuvable."
        return "NotFound"
    }
}

Export-ModuleMember -Function Register-AthenaTask, Get-AthenaTaskStatus

Write-Host "âœ… Module Athena.Scheduler chargÃ© (v1.2-Fix â€“ Auto-Scheduler Stable)."



