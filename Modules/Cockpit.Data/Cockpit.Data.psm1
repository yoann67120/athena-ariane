# ====================================================================
# Cockpit.Data.psm1 â€“ Donnees systeme temps reel
# Version : v1.3-clean
# Objectif :
#   - Fournir les infos CPU/RAM/Modules au cockpit
#   - Compatible PowerShell 5.x et 7.x
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

function Get-CockpitData {
    try {
        # Lecture CPU universelle
        $cpuObj = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
        if ($cpuObj -and $cpuObj.CounterSamples) {
            $cpu = [math]::Round($cpuObj.CounterSamples.CookedValue, 2)
        } elseif ($cpuObj -and $cpuObj.Readings) {
            $cpu = [math]::Round(($cpuObj.Readings | Measure-Object -Average).Average, 2)
        } else {
            # Fallback via CIM
            $cpu = [math]::Round((Get-CimInstance Win32_Processor |
                Measure-Object -Property LoadPercentage -Average).Average, 2)
        }
    } catch {
        $cpu = 0
    }

    try {
        $mem = Get-CimInstance Win32_OperatingSystem
        $ram = [math]::Round((($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) /
            $mem.TotalVisibleMemorySize) * 100, 2)
    } catch {
        $ram = 0
    }

    $time = (Get-Date).ToString("HH:mm:ss")
    try {
        $modulesCount = (Get-ChildItem -Path (Split-Path -Parent $PSScriptRoot) `
            -Filter *.psm1 -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    } catch {
        $modulesCount = 0
    }

    [ordered]@{
        Time    = $time
        CPU     = "$cpu %"
        RAM     = "$ram %"
        Modules = $modulesCount
    }
}

Export-ModuleMember -Function Get-CockpitData
Write-Host "Cockpit.Data.psm1 charge (collecte systeme prete - compatible PowerShell 5.x et 7.x)." -ForegroundColor Cyan



