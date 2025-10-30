# ====================================================================
# âœ… Athena.Validator.psm1
# Phase 9 â€“ VÃ©rification dâ€™intÃ©gritÃ© du socle Ariane/Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleRoot
$ModulesDir  = Join-Path $RootDir "Modules"
$LogsDir     = Join-Path $RootDir "Logs"
$MemoryDir   = Join-Path $RootDir "Memory"
$RecFile     = Join-Path $RootDir "Recommandations.json"
$IntegrityFile = Join-Path $MemoryDir "IntegrityReport.json"
$LogFile     = Join-Path $LogsDir "AthenaValidator.log"

function Write-AthenaValidatorLog {
    param([string]$Msg,[string]$L="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$L] $Msg"
}

function Invoke-AthenaValidator {
    Write-Host "`nâœ… VÃ©rification dâ€™intÃ©gritÃ© du socle Athena..." -ForegroundColor Cyan
    Write-AthenaValidatorLog "DÃ©but de la vÃ©rification dâ€™intÃ©gritÃ©."

    if (!(Test-Path $RecFile)) {
        Write-Host "âš ï¸ Fichier de recommandations introuvable : $RecFile" -ForegroundColor Yellow
        Write-AthenaValidatorLog "Recommandations.json manquant" "ERROR"
        return
    }

    # Lecture de la liste des modules attendus
    $recData = Get-Content $RecFile -Raw | ConvertFrom-Json
    $expectedPaths = @()
    foreach ($r in $recData.recommandations) {
        if ($r.path -like "Modules/*.psm1") {
            $expectedPaths += [System.IO.Path]::GetFileName($r.path)
        }
    }

    $actualModules = Get-ChildItem $ModulesDir -Filter "*.psm1" | Select-Object -ExpandProperty Name

    $missing = $expectedPaths | Where-Object { $_ -notin $actualModules }
    $extra   = $actualModules | Where-Object { $_ -notin $expectedPaths }

    # VÃ©rification taille/date des fichiers
    $modified = @()
    foreach ($f in $actualModules) {
        $full = Join-Path $ModulesDir $f
        $hash = (Get-FileHash $full -Algorithm SHA256).Hash
        $modified += @{ Name = $f; Hash = $hash }
    }

    $integrity = @{
        Date      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Missing   = $missing
        Extra     = $extra
        Modified  = $modified
        Status    = if ((@($missing).Count) -eq 0 -and (@($extra).Count) -eq 0) { "OK" } else { "ALERT" }
    }

    $integrity | ConvertTo-Json -Depth 6 | Out-File -FilePath $IntegrityFile -Encoding UTF8
    Write-AthenaValidatorLog "Rapport dâ€™intÃ©gritÃ© gÃ©nÃ©rÃ© : $IntegrityFile"

    if ((@($missing).Count) -gt 0 -or (@($extra).Count) -gt 0) {
        Write-Host "âš ï¸ Anomalies dÃ©tectÃ©es dans les modules :" -ForegroundColor Yellow
        if ((@($missing).Count) -gt 0) { Write-Host "   Manquants : $($missing -join ', ')" -ForegroundColor Red }
        if ((@($extra).Count) -gt 0)   { Write-Host "   SupplÃ©mentaires : $($extra -join ', ')" -ForegroundColor Yellow }

        Write-AthenaValidatorLog "DÃ©clenchement de la rÃ©paration automatique." "ACTION"

        try {
            Import-Module (Join-Path $ModulesDir "Athena.SelfRepair.psm1") -Force -Global
            Invoke-Expression "Invoke-AthenaSelfRepair"
        } catch {
            Write-AthenaValidatorLog "Erreur lors du dÃ©clenchement de SelfRepair : $_" "ERROR"
        }
    }
    else {
        Write-Host "âœ… Tous les modules sont conformes." -ForegroundColor Green
        Write-AthenaValidatorLog "Aucune anomalie dÃ©tectÃ©e."
    }

    Write-AthenaValidatorLog "Fin de la vÃ©rification dâ€™intÃ©gritÃ©."
    Write-Host "âœ… VÃ©rification dâ€™intÃ©gritÃ© terminÃ©e." -ForegroundColor Cyan
}
Export-ModuleMember -Function Invoke-AthenaValidator




