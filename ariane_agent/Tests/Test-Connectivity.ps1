# ====================================================================
# 🔌 Ariane V4 - Test de Connectivité Globale (v2)
# Phase 7.1G
# ====================================================================

$LogFile = "C:\Ariane-Agent\logs\Global.log"
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Add-Content $LogFile "`n[$timestamp] === PHASE 7.1G : Test de connectivité globale lancé ==="

function Test-Endpoint($test) {
    $name = $test.name
    $url = $test.url
    $method = $test.method
    Write-Host "🌐 Test de $name → $url" -ForegroundColor Cyan
    try {
        if ($method -eq "POST") {
            $body = @{action="exec"; param="Get-Date"; source="TestConnectivity"} | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -TimeoutSec 5
        } else {
            $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 5
        }
        Write-Host "✅ $name : OK" -ForegroundColor Green
        Add-Content $LogFile "[$(Get-Date -Format 'HH:mm:ss')] ✅ $name : OK ($url)"
        return $true
    } catch {
        Write-Host "❌ $name : Échec ($($_.Exception.Message))" -ForegroundColor Red
        Add-Content $LogFile "[$(Get-Date -Format 'HH:mm:ss')] ❌ $name : Échec ($url)"
        return $false
    }
}

# Liste des endpoints à vérifier
$tests = @(
    @{ name = "Usine Flask"; url = "http://localhost:5050/"; method = "GET" },
    @{ name = "AgentKit /list"; url = "http://localhost:5050/list"; method = "GET" },
    @{ name = "Cockpit Athena (port 5070)"; url = "http://localhost:5070/health"; method = "GET" },
    @{ name = "Bridge GPT (port 5000)"; url = "http://localhost:5000/execute"; method = "POST" }
)

Write-Host "🚀 Lancement des tests de connectivité..." -ForegroundColor Yellow

$results = @()
foreach ($test in $tests) {
    $status = Test-Endpoint -test $test
    $results += [PSCustomObject]@{ Service = $test.name; URL = $test.url; OK = $status }
}

$summary = $results | ConvertTo-Json -Depth 2
Add-Content $LogFile "[$(Get-Date -Format 'HH:mm:ss')] Résumé : $summary"
Write-Host "`n=== Résumé des tests ==="
$results | Format-Table

Add-Content $LogFile "`n[$(Get-Date)] === PHASE 7.1G terminée ==="
Write-Host "`n📁 Journal : $LogFile" -ForegroundColor Cyan
