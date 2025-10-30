# ====================================================================
# ðŸ›°ï¸ Ariane V4 - Watchdog.psm1
# Supervision et relance automatique du systÃ¨me Ariane/Athena
# Version : v2.2 (AutoCycle + AutoRepair)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ModulesDir = Join-Path $RootDir "Modules"

$EngineFile = Join-Path $ModulesDir "Athena.Engine.psm1"
$ReportFile = Join-Path $LogsDir "AthenaReport.log"
$AutoFile   = Join-Path $RootDir "Scripts\Reset-Athena-Auto.ps1"
$LogFile    = Join-Path $LogsDir "Watchdog.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-WatchdogLog {
    param([string]$Msg,[string]$L="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$L] $Msg"
    if (Test-Path $ReportFile) {
        Add-Content -Path $ReportFile -Value "[$t][$L][Watchdog] $Msg"
    }
}

# ====================================================================
# ðŸ”Ž VÃ©rification de lâ€™intÃ©gritÃ© du systÃ¨me
# ====================================================================
function Invoke-WatchdogCheck {
    Write-Host "`nðŸ”Ž VÃ©rification complÃ¨te du systÃ¨me Ariane..." -ForegroundColor Yellow
    $issues = @()

    if (!(Test-Path $EngineFile))  { $issues += "Athena.Engine manquant" }
    if (!(Test-Path $ReportFile))  { $issues += "AthenaReport.log absent" }
    if (!(Test-Path $MemoryDir))   { $issues += "Memory manquant" }
    if (!(Test-Path $AutoFile))    { $issues += "Script Reset-Athena-Auto.ps1 absent" }

    if ($issues.Count -eq 0) {
        Write-Host "âœ… Aucun problÃ¨me dÃ©tectÃ©." -ForegroundColor Green
        Write-WatchdogLog "VÃ©rification rÃ©ussie."
    }
    else {
        Write-Warning "âš ï¸ ProblÃ¨mes dÃ©tectÃ©s : $($issues -join ', ')"
        Write-WatchdogLog "Anomalies dÃ©tectÃ©es : $($issues -join ', ')" "WARN"
        Repair-WatchdogAnomalies -Issues $issues
    }
}

# ====================================================================
# ðŸ©¹ RÃ©paration automatique des anomalies dÃ©tectÃ©es
# ====================================================================
function Repair-WatchdogAnomalies {
    param([string[]]$Issues)

    Import-Module (Join-Path $ModulesDir "AutoPatch.psm1") -Force -Global | Out-Null

    foreach ($i in $Issues) {
        Write-Host "ðŸ©º Tentative de rÃ©paration : $i" -ForegroundColor Cyan
        Write-WatchdogLog "RÃ©paration : $i"
        try {
            Invoke-AutoPatch -Auto | Out-Null
        } catch {
            Write-Warning "âš ï¸ Erreur pendant la rÃ©paration : $_"
            Write-WatchdogLog "Erreur AutoPatch : $_" "ERROR"
        }
    }
    Write-Host "ðŸ” Relance du cycle Athena aprÃ¨s rÃ©paration..." -ForegroundColor Magenta
    Restart-Athena
}

# ====================================================================
# ðŸ” Relance manuelle ou automatique dâ€™Athena
# ====================================================================
function Restart-Athena {
    Write-Host "ðŸš€ RedÃ©marrage dâ€™Athena..." -ForegroundColor Cyan
    Write-WatchdogLog "RedÃ©marrage dâ€™Athena..."
    try {
        Import-Module $EngineFile -Force -Global | Out-Null
        if (Get-Command Invoke-AthenaCycle -ErrorAction SilentlyContinue) {
            Invoke-AthenaCycle
        }
        else {
            Write-Warning "âš ï¸ Fonction Invoke-AthenaCycle introuvable â€“ tentative dâ€™exÃ©cution via script..."
            $script = Join-Path $RootDir "Scripts\Start-Athena.ps1"
            & $script
        }
    } catch {
        Write-Warning "âš ï¸ Ã‰chec du redÃ©marrage : $_"
        Write-WatchdogLog "Erreur redÃ©marrage : $_" "ERROR"
    }
}

# ====================================================================
# ðŸ•’ Cycle planifiÃ© automatique (03h00)
# ====================================================================
function Invoke-WatchdogAutoCycle {
    $hour = (Get-Date).Hour
    if ($hour -eq 3) {
        Write-Host "ðŸ•’ 03h00 dÃ©tectÃ© â†’ Lancement automatique du cycle Athena..." -ForegroundColor Yellow
        Write-WatchdogLog "Cycle automatique 03h00 dÃ©clenchÃ©."
        try {
            Import-Module $EngineFile -Force -Global | Out-Null
            Invoke-AthenaCycle
        } catch {
            Write-Warning "âš ï¸ Erreur pendant le cycle automatique : $_"
            Write-WatchdogLog "Erreur cycle auto : $_" "ERROR"
        }
    }
}

# ====================================================================
# ðŸ”„ Surveillance temps rÃ©el (mode continu)
# ====================================================================
function Start-WatchdogRealtime {
    Write-Host "`nðŸ•“ Surveillance temps rÃ©el activÃ©e (vÃ©rif. toutes les 5 min)..." -ForegroundColor Yellow
    while ($true) {
        Invoke-WatchdogCheck
        Invoke-WatchdogAutoCycle
        Start-Sleep -Seconds 300
    }
}

Export-ModuleMember -Function Invoke-WatchdogCheck, Repair-WatchdogAnomalies, Restart-Athena, Start-WatchdogRealtime, Invoke-WatchdogAutoCycle

# ====================================================================
# ðŸ§© FIN DU MODULE
# ====================================================================
Write-Host "âœ… Watchdog.psm1 v2.2 chargÃ© (supervision automatique + cycle autonome 03h00)." -ForegroundColor Cyan



