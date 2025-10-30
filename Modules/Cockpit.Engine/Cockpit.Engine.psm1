# ====================================================================
# âš™ï¸ Cockpit.Engine.psm1 â€“ Moteur du cockpit K2000
# Version : v1.0
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

Import-Module "$((Split-Path -Parent $PSScriptRoot))\Modules\Cockpit.Data.psm1" -Force -Global

function Start-CockpitEngine {
    Write-Host "`nâš™ï¸ DÃ©marrage du moteur du Cockpit K2000..." -ForegroundColor Cyan

    while ($true) {
        $data = Get-CockpitData
        $cpu  = $data.CPU
        $ram  = $data.RAM
        $time = $data.Time

        Write-Host ("`r[{0}] CPU: {1} | RAM: {2} | Modules: {3}" -f $time, $cpu, $ram, $data.Modules) -NoNewline
        Start-Sleep -Seconds 2
    }
}

Export-ModuleMember -Function Start-CockpitEngine
Write-Host "âš™ï¸ Module Cockpit.Engine.psm1 chargÃ© (rafraÃ®chissement en temps rÃ©el prÃªt)."




