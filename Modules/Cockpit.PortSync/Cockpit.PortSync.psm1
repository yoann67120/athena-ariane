# ====================================================================
# ðŸŒ Cockpit.PortSync.psm1 â€“ SÃ©lection automatique du port Cockpit
# ====================================================================

function Invoke-PortSync {
    param(
        [int[]]$Ports = @(9191,9192,9291,9391),
        [string]$MemoryFile = "$env:ARIANE_ROOT\Memory\SystemStatus.json"
    )

    Import-Module "$env:ARIANE_ROOT\Modules\Athena.HttpRepair.psm1" -Force
    $port = Invoke-HttpRepair -Ports $Ports
    if (-not $port) { return }

    Write-Host "ðŸ§  Port retenu : $port"
    $data = @{ Port = $port; LastUpdate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
    $data | ConvertTo-Json | Out-File $MemoryFile -Encoding utf8

    Write-Host "ðŸš€ Lancement dâ€™Ariane sur le port $port..."
    Start-Process pwsh -ArgumentList "-File '$env:ARIANE_ROOT\Ariane.ps1'"
}

Export-ModuleMember -Function Invoke-PortSync


