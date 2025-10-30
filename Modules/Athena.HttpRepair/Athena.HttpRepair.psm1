# ====================================================================
# ðŸ› ï¸ Athena.HttpRepair.psm1 â€“ Auto-rÃ©paration HTTP.sys & ports Ariane
# ====================================================================

function Invoke-HttpRepair {
    param(
        [int[]]$Ports = @(9191,9192,9291,9391),
        [string]$User = $env:USERNAME
    )

    Write-Host "ðŸ©º VÃ©rification du service HTTP..." -ForegroundColor Cyan
    $svc = Get-Service -Name http -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Warning "âš ï¸ Service HTTP introuvable !"
        return
    }

    if ($svc.Status -ne "Running") {
        Write-Host "ðŸ”„ DÃ©marrage du service HTTP..."
        try { Start-Service http -ErrorAction Stop } catch { Write-Warning $_ }
    }

    # ðŸ” Test de validitÃ© de la table URLACL
    try { netsh http show urlacl | Out-Null }
    catch {
        Write-Warning "âš ï¸ Table URL corrompue : nettoyage registre..."
        reg delete "HKLM\SYSTEM\CurrentControlSet\Services\HTTP\Parameters\UrlAclInfo" /f | Out-Null
        Start-Sleep -Seconds 2
        net start http | Out-Null
    }

    foreach ($port in $Ports) {
        $used = (netstat -ano | findstr ":$port") -ne $null
        if ($used) {
            Write-Host "â›” Port $port occupÃ©, test du suivant..." -ForegroundColor Yellow
            continue
        }
        try {
            netsh http delete urlacl url="http://+:$port/" 2>$null | Out-Null
            netsh http add urlacl url="http://+:$port/" user="$User" | Out-Null
            Write-Host "âœ… Port $port prÃªt pour Ariane." -ForegroundColor Green
            return $port
        } catch {
            Write-Warning "âš ï¸ Ã‰chec sur $port : $_"
        }
    }

    Write-Error "âŒ Aucun port disponible parmi $Ports"
    return $null
}

Export-ModuleMember -Function Invoke-HttpRepair


