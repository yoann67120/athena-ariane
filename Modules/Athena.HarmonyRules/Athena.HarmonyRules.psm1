# ====================================================================
# ðŸ§  Athena.HarmonyRules.psm1 â€“ Apprentissage adaptatif & ajustement
# Version : v1.0-Rules-Stable
# Auteur  : Athena Core Engine / Ariane V4
# ====================================================================
# Objectif :
#   - Ajuster automatiquement les seuils dâ€™harmonie selon expÃ©rience
#   - GÃ©rer les sauvegardes, rollbacks et apprentissage adaptatif
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$MemoryDir = Join-Path $RootDir "Memory"
$LogsDir   = Join-Path $RootDir "Logs"
$RulesFile = Join-Path $MemoryDir "AutoHarmonyRules.json"
$LogFile   = Join-Path $LogsDir "AthenaHarmonyRules.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-RulesLog {
    param([string]$Message,[string]$Level="INFO")
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level] $Message"
}

# ðŸ”¹ Charger les rÃ¨gles actuelles
function Load-AutoHarmonyRules {
    if (!(Test-Path $RulesFile)) { return @{} }
    try { return (Get-Content $RulesFile -Raw | ConvertFrom-Json) } catch { return @{} }
}

# ðŸ”¹ Proposer un changement (DryRun)
function Propose-RuleChange {
    param([hashtable]$NewValues)
    $current = Load-AutoHarmonyRules
    Write-Host "ðŸ” Proposition de nouvelles rÃ¨gles (DryRun) :"
    $diff = Compare-Object ($current.GetEnumerator() | % { $_.Key }) ($NewValues.Keys)
    Write-Host ($NewValues | ConvertTo-Json -Depth 3)
    Write-RulesLog "Proposition DryRun gÃ©nÃ©rÃ©e."
    return $NewValues
}

# ðŸ”¹ Appliquer un changement (avec approbation)
function Apply-RuleChange {
    param([hashtable]$NewValues,[switch]$Confirm)
    if (-not $Confirm) {
        Write-Host "âš ï¸ Utiliser -Confirm pour appliquer dÃ©finitivement."
        return
    }
    $bak = "$RulesFile.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
    if (Test-Path $RulesFile) { Copy-Item $RulesFile $bak -Force }
    $NewValues | ConvertTo-Json -Depth 3 | Out-File $RulesFile -Encoding utf8
    Write-RulesLog "RÃ¨gles appliquÃ©es et sauvegardÃ©es."
}

# ðŸ”¹ Ajustement automatique progressif
function AutoTune-Thresholds {
    $rules = Load-AutoHarmonyRules
    if (-not $rules.SafeOps_CPU_Max) { $rules.SafeOps_CPU_Max = 85 }
    $rules.SafeOps_CPU_Max = [math]::Max(($rules.SafeOps_CPU_Max - 1),70)
    Write-Host "ðŸ”§ AutoTune proposÃ© : SafeOps_CPU_Max=$($rules.SafeOps_CPU_Max)"
    Write-RulesLog "AutoTune simulÃ© (DryRun)."
}

# ðŸ”¹ Rollback
function Rollback-RuleSet {
    $bak = Get-ChildItem "$RulesFile.bak_*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($bak) {
        Copy-Item $bak.FullName $RulesFile -Force
        Write-Host "â™»ï¸ RÃ¨gles restaurÃ©es depuis $($bak.Name)"
        Write-RulesLog "Rollback exÃ©cutÃ©."
    } else {
        Write-Warning "Aucune sauvegarde trouvÃ©e."
    }
}

Export-ModuleMember -Function Load-AutoHarmonyRules,Propose-RuleChange,Apply-RuleChange,AutoTune-Thresholds,Rollback-RuleSet
Write-Host "ðŸ§  Module Athena.HarmonyRules.psm1 chargÃ© (v1.0-Rules-Stable)." -ForegroundColor Cyan


