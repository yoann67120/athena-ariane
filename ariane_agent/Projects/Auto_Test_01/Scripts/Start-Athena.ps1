Write-Host "=== Démarrage AthenaV4 ===" -ForegroundColor Cyan
Import-Module "$PSScriptRoot\..\Modules\Athena.ServerCore.psm1" -Force
Import-Module "$PSScriptRoot\..\Modules\Athena.Engine.psm1" -Force
Import-Module "$PSScriptRoot\..\Modules\Athena.AutoRepair.psm1" -Force
Write-Host "✅ AthenaV4 initialisée avec succès." -ForegroundColor Green
