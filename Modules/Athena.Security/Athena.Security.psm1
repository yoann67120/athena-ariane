# ====================================================================
# ðŸ” Athena.Security.psm1 â€“ ContrÃ´le dâ€™intÃ©gritÃ© et sÃ©curitÃ© interne
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir  = Split-Path -Parent $PSScriptRoot
$ModulesDir = Join-Path $RootDir "Modules"
$LogsDir  = Join-Path $RootDir "Logs"
$LogFile  = Join-Path $LogsDir "AthenaSecurity.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-AthenaSecurityLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t] $Msg"
}

function Get-FileHashShort($Path) {
    if (Test-Path $Path) {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.Substring(0,16)
    } else { return "MISSING" }
}

function Invoke-AthenaSecurity {
    Write-Host "ðŸ”’ VÃ©rification de l'intÃ©gritÃ© des modules..." -ForegroundColor Cyan
    Write-AthenaSecurityLog "=== ContrÃ´le d'intÃ©gritÃ© lancÃ© ==="

    $CriticalModules = @(
        "Core.psm1",
        "LocalModel.psm1",
        "AutoPatch.psm1",
        "Watchdog.psm1",
        "Athena.Engine.psm1",
        "ActionEngine.psm1"
    )

    foreach ($mod in $CriticalModules) {
        $path = Join-Path $ModulesDir $mod
        $hash = Get-FileHashShort $path
        Write-AthenaSecurityLog "$mod â†’ $hash"
        if ($hash -eq "MISSING") {
            Write-Warning "âš ï¸ Module manquant : $mod"
            Write-AthenaSecurityLog "âš ï¸ Module manquant : $mod"
        }
    }

    Write-Host "âœ… VÃ©rification d'intÃ©gritÃ© terminÃ©e." -ForegroundColor Green
    Write-AthenaSecurityLog "âœ… VÃ©rification d'intÃ©gritÃ© terminÃ©e."
}

Export-ModuleMember -Function Invoke-AthenaSecurity




