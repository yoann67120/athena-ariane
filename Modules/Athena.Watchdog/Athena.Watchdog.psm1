# ====================================================================
#  Athena.Watchdog.psm1  v2.0-StableGuardian
# --------------------------------------------------------------------
# Auteur : Yoann Rousselle / Athena Core
# Rle   :
#   - Surveille l'tat des processus et services essentiels d'Athena
#   - Relance automatiquement les modules ou le cockpit en cas de panne
#   - Journalise les anomalies dans Logs\AthenaGuardian.log
#   - Notifie le SelfCoordinator / HybridLink / Cockpit
#   - Prpar pour Phases 3537 (SelfBuilder / HybridSync / SelfEvolution)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# --- Dossiers --------------------------------------------------------
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir 'Logs'
$ModulesDir = Join-Path $RootDir 'Modules'
$GuardianLog = Join-Path $LogsDir 'AthenaGuardian.log'
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

# ====================================================================
#  Fonction de log
# ====================================================================
function Write-GuardianLog {
    param([string]$Msg,[string]$Level='INFO')
    $t=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $GuardianLog -Value "[$t][$Level] $Msg"
}

# ====================================================================
#  Vrification du cockpit (port 8080)
# ====================================================================
function Test-CockpitStatus {
    try {
        $request = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
        return $request.StatusCode -eq 200
    } catch { return $false }
}

# ====================================================================
#  Surveillance des processus PowerShell et Cockpit
# ====================================================================
function Invoke-AthenaWatchdog {
    Write-Host "`n Surveillance systme Athena..." -ForegroundColor Cyan
    Write-GuardianLog "=== Cycle Watchdog lanc ==="

    # Vrification du cockpit
    if (-not (Test-CockpitStatus)) {
        Write-GuardianLog " Cockpit inactif  tentative de redmarrage..."
        $Cockpit = Join-Path $ModulesDir 'Cockpit.Server-DisplayFix.psm1'
        if (Test-Path $Cockpit) {
            try {
                Import-Module $Cockpit -Force -Global
                if (Get-Command Start-CockpitServer -ErrorAction SilentlyContinue) {
                    Start-CockpitServer | Out-Null
                    Write-GuardianLog " Cockpit redmarr avec succs."
                }
            } catch { Write-GuardianLog " Erreur redmarrage cockpit : $_" }
        } else {
            Write-GuardianLog " Module cockpit introuvable."
        }
    } else {
        Write-GuardianLog " Cockpit oprationnel."
    }

    # Vrification de lutilisation CPU / RAM
    try {
       $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').Readings[0]
$ram = (Get-Counter '\Memory\Available MBytes').Readings[0]

        Write-GuardianLog (" Ressources : CPU={0:N1}% | RAM libre={1:N0} Mo" -f $cpu,$ram)
        if ($cpu -gt 95) { Write-GuardianLog " Charge CPU leve !" }
        if ($ram -lt 500) { Write-GuardianLog " Mmoire faible !" }
    } catch { Write-GuardianLog " Erreur lecture ressources : $_" }

    Send-AthenaWatchdogStatus -Status 'CycleComplete'
    Write-GuardianLog "=== Fin du cycle Watchdog ==="
}

# ====================================================================
#  Tche planifie Watchdog (toutes les 5 min)
# ====================================================================
function Register-AthenaWatchdogTask {
    try {
        $TaskName = 'Athena_Watchdog_Monitor'
        $exists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if (-not $exists) {
            $ScriptBlock = "Import-Module `"$($MyInvocation.MyCommand.Path)`"; Invoke-AthenaWatchdog"
            $action  = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument "-Command $ScriptBlock"
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)
            Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Description 'Surveillance continue dAthena' -User 'SYSTEM' -RunLevel Highest | Out-Null
            Write-GuardianLog " Tche planifie cre ($TaskName)"
        } else {
            Write-GuardianLog " Tche Watchdog dj existante."
        }
    } catch { Write-GuardianLog " Erreur cration tche : $_" }
}

# ====================================================================
#  Communication systme
# ====================================================================
function Send-AthenaWatchdogStatus {
    param([string]$Status)
    try {
        if (Get-Command -Name Update-AthenaStatus -ErrorAction SilentlyContinue) {
            Update-AthenaStatus -Module 'Watchdog' -Status $Status
        } elseif (Get-Command -Name Send-HybridSignal -ErrorAction SilentlyContinue) {
            Send-HybridSignal -Channel 'Watchdog' -Payload @{ State=$Status }
        } else {
            Write-GuardianLog " Aucun canal de notification dtect."
        }
    } catch { Write-GuardianLog " Erreur de notification : $_" }
}

# ====================================================================
#  Hooks Phases 3537
# ====================================================================
#region Phase35_SelfBuilder
# Placeholder : Auto-gnration des scripts de surveillance manquants.
#endregion
#region Phase36_HybridSync
# Placeholder : Synchronisation de ltat du Watchdog entre machines Athena.
#endregion
#region Phase37_SelfEvolution
# Placeholder : Ajustement automatique de la frquence de surveillance.
#endregion

# ====================================================================
#  VÃ©rification et auto-rÃ©paration HTTP.sys / Cockpit
# ====================================================================

function Test-HttpHealth {
    try {
        $svc = Get-Service -Name http -ErrorAction SilentlyContinue
        if (-not $svc) { return $false }
        if ($svc.Status -ne 'Running') { return $false }
        $urls = (netsh http show urlacl) 2>$null
        if ($urls -match 'Descripteur non valide') { return $false }
        return $true
    } catch { return $false }
}

function Repair-HttpIfNeeded {
    if (-not (Test-HttpHealth)) {
        Write-GuardianLog "âš ï¸ Service HTTP corrompu, lancement d'Athena.HttpRepair..."
        $repair = Join-Path $ModulesDir 'Athena.HttpRepair.psm1'
        if (Test-Path $repair) {
            try {
                Import-Module $repair -Force -Global
                $port = Invoke-HttpRepair -Ports @(9191,9192,9291,9391)
                Write-GuardianLog "âœ… HTTP rÃ©parÃ©, port $port prÃªt."
                return $port
            } catch {
                Write-GuardianLog "âŒ Ã‰chec de la rÃ©paration HTTP : $_"
                return $null
            }
        } else {
            Write-GuardianLog "âŒ Module Athena.HttpRepair.psm1 introuvable."
            return $null
        }
    } else {
        Write-GuardianLog "ðŸ§© HTTP.sys sain."
        return $null
    }
}

# ðŸ” Extension du Watchdog principal
function Invoke-AthenaWatchdog {
    Write-Host "`nðŸ” Surveillance systÃ¨me Athena..." -ForegroundColor Cyan
    Write-GuardianLog "=== Cycle Watchdog lancÃ© ==="

    # VÃ©rifie et rÃ©pare HTTP.sys si besoin
    $FixedPort = Repair-HttpIfNeeded
    if ($FixedPort) {
        Write-Host "ðŸŒ RedÃ©marrage du cockpit sur port $FixedPort"
        try {
            Import-Module (Join-Path $ModulesDir 'Cockpit.Server.psm1') -Force -Global
            Start-CockpitServer -Port $FixedPort | Out-Null
            Write-GuardianLog "âœ… Cockpit redÃ©marrÃ© sur port $FixedPort"
        } catch {
            Write-GuardianLog "âŒ Erreur redÃ©marrage cockpit : $_"
        }
    } else {
        # VÃ©rification normale du cockpit (hÃ©ritÃ©e)
        if (-not (Test-CockpitStatus)) {
            Write-GuardianLog "âš ï¸ Cockpit inactif, tentative de redÃ©marrage..."
            $Cockpit = Join-Path $ModulesDir 'Cockpit.Server.psm1'
            if (Test-Path $Cockpit) {
                try {
                    Import-Module $Cockpit -Force -Global
                    Start-CockpitServer | Out-Null
                    Write-GuardianLog "âœ… Cockpit redÃ©marrÃ© avec succÃ¨s."
                } catch { Write-GuardianLog "âŒ Erreur redÃ©marrage cockpit : $_" }
            } else {
                Write-GuardianLog "âŒ Module cockpit introuvable."
            }
        } else {
            Write-GuardianLog "ðŸŸ¢ Cockpit opÃ©rationnel."
        }
    }

    # ContrÃ´le ressources CPU / RAM (inchangÃ©)
    try {
        $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').Readings[0]
        $ram = (Get-Counter '\Memory\Available MBytes').Readings[0]
        Write-GuardianLog ("ðŸ”§ Ressources : CPU={0:N1}% | RAM libre={1:N0} Mo" -f $cpu,$ram)
        if ($cpu -gt 95) { Write-GuardianLog "âš ï¸ Charge CPU Ã©levÃ©e !" }
        if ($ram -lt 500) { Write-GuardianLog "âš ï¸ MÃ©moire faible !" }
    } catch { Write-GuardianLog "âŒ Erreur lecture ressources : $_" }

    Send-AthenaWatchdogStatus -Status 'CycleComplete'
    Write-GuardianLog "=== Fin du cycle Watchdog ==="
}

# ====================================================================
#  Exportation
# ====================================================================
Export-ModuleMember -Function Invoke-AthenaWatchdog, Register-AthenaWatchdogTask, Send-AthenaWatchdogStatus, Write-GuardianLog
Write-Host " Module Athena.Watchdog.psm1 charg (v2.0-StableGuardian)." -ForegroundColor Cyan
# ====================================================================



