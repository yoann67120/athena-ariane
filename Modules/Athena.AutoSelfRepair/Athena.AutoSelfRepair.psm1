# ====================================================================
# Athena.AutoSelfRepair.psm1 â€“ Autonomous Fix Engine (v2.1)
# Auteur : Yoann R. / Ariane V4
# Date   : 17/10/2025
# Objectif :
#   Surveiller les logs rÃ©cents, dÃ©tecter des erreurs connues et lancer
#   automatiquement le correctif global (Athena_GlobalFix.ps1)
# ====================================================================

function Invoke-AutoSelfRepair {
    param(
        [string]$Root = (Split-Path $PSScriptRoot -Parent)
    )

    $LogsDir    = Join-Path $Root "Logs"
    $ModulesDir = Join-Path $Root "Modules"
    $FixScript  = Join-Path $Root "Scripts\Athena_GlobalFix.ps1"
    $ReportFile = Join-Path $LogsDir "AutoSelfRepair.log"

    "[{0}] DÃ©marrage du moteur AutoSelfRepair..." -f (Get-Date) | Out-File $ReportFile

    # --- 1. Analyse des logs rÃ©cents (12 derniÃ¨res heures) ---
    $RecentLogs = Get-ChildItem $LogsDir -Recurse -Include *.log -ErrorAction SilentlyContinue |
                  Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-12) }

    $Errors = @()

    foreach ($log in $RecentLogs) {
        $lines = Get-Content $log.FullName -Tail 80
        foreach ($line in $lines) {
            if ($line -match 'op_Addition')                 { $Errors += 'SelfRepair' }
            elseif ($line -match 'ModulesDir')              { $Errors += 'AutoMaintain' }
            elseif ($line -match 'property.*Count')         { $Errors += 'IntegrationAdvisor' }
            elseif ($line -match 'Unexpected character.*JSON') { $Errors += 'AutoPatch' }
        }
    }

    if (-not $Errors) {
        Add-Content $ReportFile "Aucune anomalie critique dÃ©tectÃ©e."
        Add-Content $ReportFile "Cycle AutoSelfRepair terminÃ© Ã  $(Get-Date)."
        return
    }

    $UniqueErrors = $Errors | Sort-Object -Unique
    Add-Content $ReportFile ("Anomalies dÃ©tectÃ©es : {0}" -f ($UniqueErrors -join ', '))

    # --- 2. Application du correctif global ---
    if (Test-Path $FixScript) {
        try {
            & $FixScript | Out-Null
            Add-Content $ReportFile "Correctif global exÃ©cutÃ© automatiquement."
        }
        catch {
            Add-Content $ReportFile ("Erreur pendant l'exÃ©cution de {0} : {1}" -f $FixScript, $_)
        }
    }
    else {
        Add-Content $ReportFile ("Script {0} introuvable." -f $FixScript)
    }

    # --- 3. RÃ©sumÃ© final ---
    Add-Content $ReportFile ("Cycle AutoSelfRepair terminÃ© Ã  {0}" -f (Get-Date))
}

Export-ModuleMember -Function Invoke-AutoSelfRepair



