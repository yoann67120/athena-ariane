# ====================================================================
# ðŸ›¡ï¸ Athena.HarmonyGuardian.psm1 â€“ Surveillance & auto-rÃ©paration douce
# Version : v1.0-Stable (non agressif)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir "Logs"
$LogFile   = Join-Path $LogsDir "AthenaGuardian.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

$global:HarmonyGuardian_AutoRepairEnabled = $false

function Write-HarmonyLog {
    param([string]$Msg,[string]$Level="INFO")
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level] $Msg"
}

function Start-HarmonyGuardian {
    param([switch]$QuickCheck,[switch]$Safe)

    Write-Host "`nðŸ›¡ï¸ Lancement HarmonyGuardian (mode $($Safe ? 'SAFE' : 'NORMAL'))..." -ForegroundColor Cyan
    Write-HarmonyLog "Cycle dÃ©marrÃ©."

    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $ram = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,2)
    Write-Host "CPU : $([math]::Round($cpu,2))% | RAM libre : $ram MB" -ForegroundColor Gray
    Write-HarmonyLog "CPU=$cpu RAM=$ram MB"

    if ($cpu -gt 90) {
        Write-Warning "âš ï¸ Charge CPU Ã©levÃ©e."
        Write-HarmonyLog "CPU Ã©levÃ©."
    }

    if (-not $Safe -and $global:HarmonyGuardian_AutoRepairEnabled) {
        if (Get-Command Invoke-AutoPatch -ErrorAction SilentlyContinue) {
            Write-Host "ðŸ”§ RÃ©paration automatique autorisÃ©e..." -ForegroundColor Yellow
            Invoke-AutoPatch
        }
    }

    Write-HarmonyLog "Cycle terminÃ©."
    Write-Host "âœ… VÃ©rification HarmonyGuardian terminÃ©e.`n" -ForegroundColor Green
}

Export-ModuleMember -Function Start-HarmonyGuardian
Write-Host "ðŸ›¡ï¸ HarmonyGuardian v1.0-Stable chargÃ© (surveillance douce)." -ForegroundColor Cyan



