# ====================================================================
# ðŸ›¡ï¸ Athena.EvolutionGuardian.psm1 â€“ v1.0-StabilityProtector
# Objectif :
#   - VÃ©rifier lâ€™intÃ©gritÃ© du fichier EvolutionPlans.json
#   - ContrÃ´ler la validitÃ© des sauvegardes dans /Memory/Backups
#   - Restaurer la derniÃ¨re version stable si une anomalie est dÃ©tectÃ©e
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$RegistryFile = Join-Path $MemoryDir "EvolutionPlans.json"
$BackupDir = Join-Path $MemoryDir "Backups"
$LogFile = Join-Path $LogsDir "EvolutionGuardian.log"

function Write-GuardianLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ” VÃ©rifie l'intÃ©gritÃ© du fichier principal
# ====================================================================
function Test-EvolutionRegistryIntegrity {
    if (!(Test-Path $RegistryFile)) {
        Write-GuardianLog "âŒ Fichier EvolutionPlans.json introuvable." "ERROR"
        return $false
    }

    try {
        $data = Get-Content $RegistryFile -Raw | ConvertFrom-Json
        if ($null -eq $data -or $data.Count -eq 0) {
            Write-GuardianLog "âŒ Fichier vide ou structure invalide." "ERROR"
            return $false
        }

        $phase35 = $data | Where-Object { $_.Phase -eq 35 -and $_.Statut -match "ValidÃ©e" }
        if ($null -eq $phase35) {
            Write-GuardianLog "âš ï¸ Phase 35 absente ou non validÃ©e dans le registre." "WARN"
            return $false
        }

        Write-GuardianLog "âœ… Fichier EvolutionPlans.json valide et phase 35 confirmÃ©e."
        return $true
    } catch {
        Write-GuardianLog "âŒ Erreur de lecture JSON : $_" "ERROR"
        return $false
    }
}

# ====================================================================
# ðŸ’¾ Restaure la derniÃ¨re sauvegarde stable
# ====================================================================
function Restore-LastValidBackup {
    if (!(Test-Path $BackupDir)) {
        Write-GuardianLog "âš ï¸ Aucun rÃ©pertoire de sauvegarde trouvÃ©." "WARN"
        return
    }

    $backups = Get-ChildItem -Path $BackupDir -Filter "EvolutionPlans_*.json" | Sort-Object LastWriteTime -Descending
    foreach ($b in $backups) {
        try {
            $test = Get-Content $b.FullName -Raw | ConvertFrom-Json
            $phase35 = $test | Where-Object { $_.Phase -eq 35 -and $_.Statut -match "ValidÃ©e" }
            if ($phase35) {
                Copy-Item $b.FullName $RegistryFile -Force
                Write-GuardianLog "ðŸ” Restauration rÃ©ussie depuis $($b.Name)."
                return
            }
        } catch {
            Write-GuardianLog "âš ï¸ Sauvegarde $($b.Name) corrompue, test ignorÃ©." "WARN"
        }
    }

    Write-GuardianLog "âŒ Aucune sauvegarde valide trouvÃ©e pour restauration." "ERROR"
}

# ====================================================================
# ðŸ§  VÃ©rifie et restaure si nÃ©cessaire
# ====================================================================
function Invoke-EvolutionGuardian {
    Write-Host "`nðŸ›¡ï¸ VÃ©rification dâ€™intÃ©gritÃ© du registre dâ€™Ã©volution..." -ForegroundColor Cyan
    $ok = Test-EvolutionRegistryIntegrity
    if (-not $ok) {
        Write-Host "âš ï¸ Anomalie dÃ©tectÃ©e. Tentative de restauration..." -ForegroundColor Yellow
        Restore-LastValidBackup
    } else {
        Write-Host "âœ… Registre valide â€“ aucune restauration nÃ©cessaire." -ForegroundColor Green
    }
}

# ====================================================================
# ðŸ” ExÃ©cution automatique planifiÃ©e
# ====================================================================
function Start-EvolutionGuardianMonitor {
    <#
      Ã€ planifier chaque nuit avant lâ€™exÃ©cution dâ€™AutoEvolution.
      Exemple :
      04:00 â†’ Start-EvolutionGuardianMonitor
      04:30 â†’ Athena_SelfAwareness_Daily.ps1
    #>
    Write-Host "`nðŸ•“ DÃ©marrage du moniteur EvolutionGuardian..." -ForegroundColor Cyan
    Invoke-EvolutionGuardian
}

Export-ModuleMember -Function `
    Write-GuardianLog, `
    Test-EvolutionRegistryIntegrity, `
    Restore-LastValidBackup, `
    Invoke-EvolutionGuardian, `
    Start-EvolutionGuardianMonitor

Write-Host "ðŸ›¡ï¸ Module Athena.EvolutionGuardian.psm1 chargÃ© (v1.0-StabilityProtector)." -ForegroundColor Cyan



