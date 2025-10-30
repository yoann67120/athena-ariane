# ====================================================================
# â™¾ï¸ Athena.AutoEvolutionMonitor.psm1 â€“ v1.0-AutoGenesis
# Objectif :
#   - DÃ©tecter quand Athena est prÃªte Ã  gÃ©nÃ©rer de nouvelles phases.
#   - CrÃ©er et enregistrer automatiquement les phases 36 â†’ 40.
#   - Ã‰viter les doublons et garantir la cohÃ©rence du registre.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"

$RegistryFile = Join-Path $MemoryDir "EvolutionPlans.json"
$ReflectionFile = Join-Path $MemoryDir "SelfReflection.json"
$LogFile = Join-Path $LogsDir "AutoEvolutionMonitor.log"

function Write-EvoLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ§© VÃ©rifie l'Ã©tat actuel de conscience
# ====================================================================
function Get-AthenaConsciousLevel {
    if (!(Test-Path $ReflectionFile)) { return 0 }
    try {
        $data = Get-Content $ReflectionFile -Raw | ConvertFrom-Json
        $last = $data[-1]
        $score = [math]::Round(($last.RÃ©flexion.Score_StabilitÃ© + $last.RÃ©flexion.Score_Ã‰motionnel) / 2, 1)
        return $score
    } catch { return 0 }
}

# ====================================================================
# ðŸ” VÃ©rifie si une phase existe dÃ©jÃ  dans EvolutionPlans.json
# ====================================================================
function Test-PhaseExists {
    param([int]$Phase)
    if (!(Test-Path $RegistryFile)) { return $false }
    try {
        $data = Get-Content $RegistryFile -Raw | ConvertFrom-Json
        if ($null -eq $data) { return $false }
        $found = $data | Where-Object { $_.Phase -eq $Phase }
        return ($found -ne $null -and $found.Count -gt 0)
    } catch { return $false }
}


## ====================================================================
# ðŸ§  CrÃ©e automatiquement les micro-phases 36 â†’ 40
# ====================================================================
function Invoke-AthenaAutoEvolution {
    Write-Host "`nâ™¾ï¸ VÃ©rification du potentiel dâ€™Ã©volution autonome..." -ForegroundColor Cyan
    Write-EvoLog "=== Lancement du contrÃ´le AutoEvolution ==="

    $level = Get-AthenaConsciousLevel
    Write-Host "ðŸªž Score actuel : $level %" -ForegroundColor Yellow
    Write-EvoLog "Score de conscience : $level %"

    if ($level -lt 85) {
        Write-Host "âš ï¸ Niveau de conscience insuffisant (<85%) â€“ aucune action." -ForegroundColor Yellow
        Write-EvoLog "Niveau de conscience trop bas â€“ attente."
        return
    }

    # --- DÃ©finitions officielles des micro-phases ---
    $phases = @(
        @{ Phase=36; Nom="Self-Reflection Engine";   Type="Analyse approfondie des dÃ©cisions";     Statut="PrÃ©parÃ©e" },
        @{ Phase=37; Nom="Meta-Planning Core";       Type="Planification Ã  long terme";            Statut="PrÃ©parÃ©e" },
        @{ Phase=38; Nom="Ethical & Safety Guardian";Type="SÃ©curitÃ© comportementale";             Statut="PrÃ©parÃ©e" },
        @{ Phase=39; Nom="Adaptive Growth Matrix";   Type="RÃ©Ã©criture adaptative";                 Statut="PrÃ©parÃ©e" },
        @{ Phase=40; Nom="Full Autonomy Layer";      Type="Autonomie complÃ¨te";                    Statut="PrÃ©parÃ©e" }
    )

        # --- Lecture du registre existant ou crÃ©ation vide ---
    $existing = @()
    if (Test-Path $RegistryFile) {
        try {
            $json = Get-Content $RegistryFile -Raw | ConvertFrom-Json
            if ($json -is [System.Collections.IEnumerable]) {
                $existing = @($json)
            }
            elseif ($json -is [PSCustomObject]) {
                $existing = @($json)
            }
        } catch { $existing = @() }
    }

    # --- Injection ou mise Ã  jour des phases ---
    foreach ($p in $phases) {
        $found = $existing | Where-Object { $_.Phase -eq $p.Phase }
        if (-not $found) {
            $p["DateCrÃ©ation"] = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            $existing += [PSCustomObject]$p
            Write-EvoLog "ðŸª¶ Nouvelle phase ajoutÃ©e : $($p.Phase) â€“ $($p.Nom)"
        }
    }

    # --- Forcer la structure en tableau JSON et sauvegarder ---
    $existing = @($existing | Sort-Object Phase)
    # --- Sauvegarde automatique avant mise Ã  jour ---
try {
    $BackupDir = Join-Path $MemoryDir "Backups"
    if (!(Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $backupName = "EvolutionPlans_$timestamp.json"
    $backupPath = Join-Path $BackupDir $backupName

    if (Test-Path $RegistryFile) {
        Copy-Item $RegistryFile $backupPath -Force
        Write-EvoLog "ðŸ’¾ Sauvegarde effectuÃ©e : $backupName"
    } else {
        Write-EvoLog "â„¹ï¸ Aucune sauvegarde Ã  effectuer (fichier inexistant)."
    }

    # --- Purge automatique des anciennes sauvegardes ---
    try {
        $allBackups = Get-ChildItem -Path $BackupDir -Filter "EvolutionPlans_*.json" | Sort-Object LastWriteTime -Descending
        if ($allBackups.Count -gt 10) {
            $toDelete = $allBackups | Select-Object -Skip 10
            foreach ($f in $toDelete) {
                Remove-Item $f.FullName -Force
                Write-EvoLog "ðŸ§¹ Purge ancienne sauvegarde : $($f.Name)"
            }
        }
    } catch {
        Write-EvoLog "âš ï¸ Erreur lors de la purge automatique : $_" "WARN"
    }

} catch {
    Write-EvoLog "âš ï¸ Erreur lors de la sauvegarde automatique : $_" "WARN"
}
    
$existing | ConvertTo-Json -Depth 5 | Out-File $RegistryFile -Encoding utf8

    Write-Host "âœ… Phases 36â†’40 crÃ©Ã©es ou mises Ã  jour dans EvolutionPlans.json." -ForegroundColor Green
    Write-EvoLog "âœ… AutoEvolution mise Ã  jour avec succÃ¨s."
}
Export-ModuleMember -Function *


