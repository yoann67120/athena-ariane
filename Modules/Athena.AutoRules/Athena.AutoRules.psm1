# ====================================================================
# âš–ï¸ Athena.AutoRules.psm1 â€“ v1.2-OmniSafe-FIGÃ‰
# ====================================================================
# Objectif :
#   Lecture et application sÃ©curisÃ©e des rÃ¨gles apprises par Athena.AutoLearning.
#   - CrÃ©ation automatique du log.
#   - Affichage console + journalisation.
#   - Rollback avant chaque action.
#   - Protection FIGÃ‰ : exclu des reconstructions automatiques.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# FIGÃ‰ : interdit de rÃ©gÃ©nÃ©ration automatique par SelfRepair
Set-Variable -Name "Ariane_FrozenModule" -Value $true -Scope Global

# === Chemins ===
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$BackupDir  = Join-Path $RootDir "Archive"

foreach ($p in @($LogsDir,$MemoryDir,$BackupDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

$RulesFile  = Join-Path $MemoryDir "AutoRules.json"
$AuditFile  = Join-Path $LogsDir "AthenaRulesAudit.log"
$BackupFile = Join-Path $BackupDir ("AutoRules_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".bak")

# === SÃ©curitÃ© ===
# 0 = lecture seule | 1 = application sÃ»re | 2 = auto-adaptation | 3 = rÃ©Ã©criture limitÃ©e
if (-not $Global:AthenaSecurityLevel) { $Global:AthenaSecurityLevel = 2 }

function Write-RulesLog {
    param([string]$Msg,[string]$Level="INFO")
    if (!(Test-Path $AuditFile)) { New-Item -ItemType File -Path $AuditFile -Force | Out-Null }
    $t=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $AuditFile -Value "[$t][$Level] $Msg"
}

function Backup-RulesFile {
    if (Test-Path $RulesFile) {
        Copy-Item -Path $RulesFile -Destination $BackupFile -Force
        Write-RulesLog "Backup crÃ©Ã© : $BackupFile"
    }
}

function Check-Security {
    param([int]$RequiredLevel,[string]$Action)
    if ($Global:AthenaSecurityLevel -lt $RequiredLevel) {
        Write-Warning "ðŸš« Action '$Action' bloquÃ©e (niveau insuffisant)"
        Write-RulesLog "Action bloquÃ©e ($Action) - Niveau requis $RequiredLevel"
        return $false
    }
    return $true
}

# --------------------------------------------------------------------
# ðŸ”¹ Lecture du fichier de rÃ¨gles
# --------------------------------------------------------------------
function Read-AutoRules {
    if (!(Test-Path $RulesFile)) {
        Write-RulesLog "AutoRules.json absent, crÃ©ation dâ€™un modÃ¨le par dÃ©faut."
        '[{"Module":"Athena.SelfRepair","Action":"Forcer","Confidence":0.9}]' |
            Out-File -FilePath $RulesFile -Encoding utf8
    }
    try {
        $rules = Get-Content $RulesFile -Raw | ConvertFrom-Json
        Write-RulesLog "$($rules.Count) rÃ¨gle(s) chargÃ©e(s)."
        return $rules
    } catch {
        Write-Warning "âš ï¸ Erreur lecture AutoRules.json : $_"
        Write-RulesLog "Erreur JSON : $_" "ERROR"
        return @()
    }
}

# --------------------------------------------------------------------
# ðŸ”¹ Application des rÃ¨gles (correctif regex + affichage)
# --------------------------------------------------------------------
function Apply-SafeRule {
    param($rule)
    $m = $rule.Module
    $a = $rule.Action
    Write-RulesLog "Application : Module=$m | Action=$a"

    if ($m -match "SelfRepair") {
        if (Get-Command Invoke-AthenaSelfRepair -ErrorAction SilentlyContinue) {
            Write-Host "ðŸ©º Application de la rÃ¨gle : $m ($a)" -ForegroundColor Green
            Invoke-AthenaSelfRepair
            Write-RulesLog "RÃ¨gle appliquÃ©e sur $m ($a)"
        } else { Write-RulesLog "Commande SelfRepair introuvable" "WARN" }
    }
    elseif ($m -match "AutoEvolution") {
        if (Get-Command Invoke-AthenaAutoEvolution -ErrorAction SilentlyContinue) {
            Write-Host "ðŸ§¬ Application de la rÃ¨gle : $m ($a)" -ForegroundColor Green
            Invoke-AthenaAutoEvolution -Prompt "Applique les nouvelles rÃ¨gles apprises"
            Write-RulesLog "RÃ¨gle appliquÃ©e sur $m ($a)"
        } else { Write-RulesLog "Commande AutoEvolution introuvable" "WARN" }
    }
    elseif ($m -match "Scheduler") {
        if (Get-Command Invoke-AthenaScheduler -ErrorAction SilentlyContinue) {
            Write-Host "ðŸ•’ Application de la rÃ¨gle : $m ($a)" -ForegroundColor Green
            Invoke-AthenaScheduler
            Write-RulesLog "RÃ¨gle appliquÃ©e sur $m ($a)"
        } else { Write-RulesLog "Commande Scheduler introuvable" "WARN" }
    }
    else {
        Write-RulesLog "Aucune correspondance directe pour $m" "WARN"
    }
}

# --------------------------------------------------------------------
# ðŸ”¹ Fonction principale
# --------------------------------------------------------------------
function Invoke-AutoRules {
    Write-Host "`nâš™ï¸ DÃ©marrage du cycle AutoRules (OmniSafe-FIGÃ‰)..." -ForegroundColor Cyan
    Write-RulesLog "=== Cycle AutoRules lancÃ© $(Get-Date) ==="
    Backup-RulesFile

    $rules = Read-AutoRules
    if (-not $rules -or $rules.Count -eq 0) {
        Write-Host "âš ï¸ Aucune rÃ¨gle active." -ForegroundColor Yellow
        Write-RulesLog "Aucune rÃ¨gle active."
        return
    }

    foreach ($r in $rules) {
        if ($r.Confidence -lt 0.5) {
            Write-RulesLog "RÃ¨gle ignorÃ©e (Confiance < 0.5)" "WARN"
            continue
        }
        Apply-SafeRule -rule $r
    }

    Write-RulesLog "Cycle terminÃ©."
    Write-Host "âœ… Cycle AutoRules terminÃ©." -ForegroundColor Cyan
}

# --------------------------------------------------------------------
# ðŸ”¹ Affichage et diagnostic
# --------------------------------------------------------------------
function Show-AutoRulesSummary {
    $rules = Read-AutoRules
    if (-not $rules) { Write-Host "Aucune rÃ¨gle trouvÃ©e."; return }
    Write-Host "=== RÃ¨gles Actuelles ===" -ForegroundColor Cyan
    $i=1
    foreach ($r in $rules) {
        Write-Host ("[{0}] Module: {1} | Action: {2} | Confiance: {3}" -f $i,$r.Module,$r.Action,$r.Confidence)
        $i++
    }
}

function Test-AutoRulesIntegrity {
    $rules = Read-AutoRules
    if (-not $rules) { return $false }
    $valid = $true
    foreach ($r in $rules) {
        if (-not $r.Module -or -not $r.Action) {
            Write-RulesLog "RÃ¨gle incomplÃ¨te dÃ©tectÃ©e." "ERROR"
            $valid = $false
        }
    }
    if ($valid) { Write-Host "âœ… IntÃ©gritÃ© AutoRules OK." }
    else { Write-Warning "âš ï¸ ProblÃ¨mes de cohÃ©rence dÃ©tectÃ©s." }
    return $valid
}

Export-ModuleMember -Function Invoke-AutoRules,Show-AutoRulesSummary,Test-AutoRulesIntegrity
Write-Host "âœ… Module Athena.AutoRules.psm1 chargÃ© (v1.2-OmniSafe-FIGÃ‰)." -ForegroundColor Cyan



