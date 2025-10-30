# Test-Failure.ps1 — Simulations
Write-Host "🧪 Tests de panne (CTRL+C pour arrêter)"


# 1) Vérifier qu'Usine répond
try {
$r = Invoke-WebRequest -Uri "http://localhost:5050/" -UseBasicParsing -TimeoutSec 2
Write-Host "Usine répond: $($r.StatusCode)" -ForegroundColor Green
} catch { Write-Host "Usine non joignable (OK pour test)" -ForegroundColor Yellow }


# 2) Stopper temporairement un process python (ATTENTION: stoppe le premier trouvé)
$py = Get-Process python -ErrorAction SilentlyContinue | Select-Object -First 1
if ($py) {
Write-Host "Arrêt python PID=$($py.Id) pour simuler une panne Usine/Agent" -ForegroundColor Yellow
Stop-Process -Id $py.Id -Force
} else {
Write-Host "Aucun python actif — passe" -ForegroundColor Yellow
}


Start-Sleep -Seconds 3
Write-Host "✅ Si le monitor tourne, il doit relancer automatiquement."