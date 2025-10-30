# ============================================================
# ðŸ¤– Athena.Autonomy.psm1 â€“ Phase 13 : Autonomie Active
# ============================================================
# Surveille et dÃ©clenche automatiquement les cycles internes
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir   = Split-Path -Parent $PSScriptRoot
$ModulesDir = Join-Path $RootDir "Modules"
$LogDir     = Join-Path $RootDir "Logs"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$LogFile = Join-Path $LogDir "Athena_Autonomy.log"

function Write-AutoLog {
    param([string]$Msg)
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$time] $Msg"
}

# ============================================================
# ðŸš€ Cycle autonome
# ============================================================
function Invoke-AthenaAutoCycle {
    Write-Host "ðŸ¤– Lancement cycle autonome Athena..." -ForegroundColor Cyan
    Write-AutoLog "Cycle autonome lancÃ©."

    # Auto-maintenance
    if (Get-Command Invoke-AthenaSelfMaintenance -ErrorAction SilentlyContinue) {
        Invoke-AthenaSelfMaintenance
    }

    # Auto-learning
    if (Get-Command Invoke-AutoLearningPlan -ErrorAction SilentlyContinue) {
        Invoke-AutoLearningPlan
    }

    # Watchdog
    if (Get-Command Invoke-WatchdogCycle -ErrorAction SilentlyContinue) {
        Invoke-WatchdogCycle
    }

    Write-AutoLog "Cycle autonome terminÃ©."
    Write-Host "âœ… Cycle autonome terminÃ©.`n" -ForegroundColor Green
}

# ============================================================
# ðŸ” Boucle continue
# ============================================================
function Start-AthenaAutonomy {
    param([int]$IntervalMinutes = 30)
    Write-Host "ðŸ§  DÃ©marrage du moteur d'autonomie Athena (intervalle : $IntervalMinutes min)." -ForegroundColor Yellow
    Write-AutoLog "Moteur autonomie dÃ©marrÃ© ($IntervalMinutes min)."

    while ($true) {
        Invoke-AthenaAutoCycle
        Start-Sleep -Seconds ($IntervalMinutes * 60)
    }
}

Export-ModuleMember -Function Invoke-AthenaAutoCycle, Start-AthenaAutonomy
Write-Host "ðŸ§  Module Athena.Autonomy.psm1 chargÃ© (v1.0-FullCycle)" -ForegroundColor Magenta
Write-AutoLog "Module chargÃ©."


