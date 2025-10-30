function Get-FileSummary {
    param (
        [string]$Path
    )

    $files = Get-ChildItem -Path $Path -Recurse
    $summary = [ordered]@{
        'Total Files'       = $files.Count
        'Modules'           = ($files | Where-Object { $_.Extension -eq '.psm1' }).Count
        'Scripts'           = ($files | Where-Object { $_.Extension -eq '.ps1' }).Count
        'Logs'              = ($files | Where-Object { $_.Extension -eq '.log' }).Count
        'Configurations'    = ($files | Where-Object { $_.Extension -eq '.config' }).Count
        'Total Size (MB)'   = "{0:N2}" -f (($files | Measure-Object -Property Length -Sum).Sum / 1MB)
    }

    return $summary
}

function Show-AuditReport {
    param (
        [string]$DirectoryPath = '$env:ARIANE_ROOT'
    )

    if (-Not (Test-Path -Path $DirectoryPath)) {
        Write-Host "Directory not found: $DirectoryPath" -ForegroundColor Red
        return
    }

    $summary = Get-FileSummary -Path $DirectoryPath

    Write-Host "Audit Report for $DirectoryPath" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    foreach ($key in $summary.Keys) {
        Write-Host "$key : $($summary[$key])"
    }
    Write-Host "----------------------------------------"
    Write-Host "Audit terminé — prêt pour analyse de nettoyage." -ForegroundColor Green
}

Export-ModuleMember -Function Get-FileSummary, Show-AuditReport

