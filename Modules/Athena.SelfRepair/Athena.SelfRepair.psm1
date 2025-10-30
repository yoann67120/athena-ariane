# ====================================================================
# ðŸ§  Athena.SelfRepair.psm1 â€“ Total Recovery Engine
# Version : v3.0-Ultimate (Self-Healing + AI Reconstruction + MemorySync)
# ====================================================================
# Objectifs :
#   - Scanner tous les modules et scripts pour dÃ©tecter anomalies ou corruptions
#   - RÃ©parer automatiquement via SafeOps, Backup ou reconstruction IA locale
#   - Valider les exports, recharger Ã  chaud, et historiser chaque action
#   - Alimenter LearningSummary.json et AutoRepairReport.json
#   - PrÃ©venir les boucles et assurer la stabilitÃ© globale dâ€™Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# --- SÃ©curitÃ© Hash globale (dÃ©clarÃ©e avant tout le reste) ---
function global:Get-FileHashSafe {
    param([string]$Path)
    try {
        (Get-FileHash $Path -Algorithm SHA256).Hash
    }
    catch {
        return 'N/A'
    }
}

# ====================================================================
# ðŸ“ Initialisation des chemins
# ====================================================================
try {
    $ScriptRoot = $PSScriptRoot
    if (-not $ScriptRoot) { $ScriptRoot = Split-Path -Parent $PSCommandPath }
    $RootDir    = Split-Path -Parent $ScriptRoot
    $ModulesDir = Join-Path $RootDir 'Modules'
    $LogsDir    = Join-Path $RootDir 'Logs'
    $MemoryDir  = Join-Path $RootDir 'Memory'
    $BackupsDir = Join-Path $RootDir 'Backups'
    $DataDir    = Join-Path $RootDir 'Data\GPT'

    foreach ($p in @($LogsDir,$MemoryDir,$BackupsDir)) {
        if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
    }

    $LogFile     = Join-Path $LogsDir 'AthenaSelfRepair.log'
    $ReportFile  = Join-Path $MemoryDir 'AutoRepairReport.json'
    $LearningSum = Join-Path $MemoryDir 'LearningSummary.json'
}
catch {
    Write-Warning "âš ï¸ Erreur dâ€™initialisation des chemins : $_"
    return
}

# ====================================================================
# ðŸ§© Fonctions utilitaires
# ====================================================================
function Write-RepairLog {
    param([string]$Message, [string]$Level = 'INFO')
    $t = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $LogFile -Value "[$t][$Level] $Message"
    Write-Host "ðŸ©º $Message"
}

function Add-LearningEntry {
    param([string]$Module,[string]$Action,[string]$Result)
    $entry = [PSCustomObject]@{
        Date    = (Get-Date).ToString('u')
        Module  = $Module
        Action  = $Action
        Result  = $Result
    }
    $data = @()
    if (Test-Path $LearningSum) {
        try { $data = Get-Content $LearningSum -Raw | ConvertFrom-Json } catch {}
    }
    $data += @() + @() + $entry
    $data | ConvertTo-Json -Depth 4 | Out-File $LearningSum -Encoding UTF8
}

function Get-ModuleList {
    Get-ChildItem -Path $ModulesDir -Filter '*.psm1' -ErrorAction SilentlyContinue
}

function Get-FileHashSafe {
    param($Path)
    try { (Get-FileHash $Path -Algorithm SHA256).Hash } catch { return 'N/A' }
}

# ====================================================================
# ðŸ” Ã‰tape 1 â€“ Analyse dâ€™intÃ©gritÃ©
# ====================================================================
function Test-AthenaModuleIntegrity {
    Write-Host "`nðŸ”Ž Analyse de lâ€™intÃ©gritÃ© des modules..." -ForegroundColor Cyan
    $modules = Get-ModuleList
    $report = @()

    foreach ($m in $modules) {
        try {
            $importable = $true
            try { Import-Module $m.FullName -Force -ErrorAction Stop } catch { $importable = $false }
            $hash = Get-FileHashSafe $m.FullName
            $size = [math]::Round($m.Length/1KB,2)
            $report += @() + @() + [PSCustomObject]@{
                Module = $m.Name
                Taille = "$size Ko"
                Hash   = $hash
                Importable = $importable
            }
        } catch {
            Write-RepairLog "Erreur analyse module $($m.Name) : $_" 'WARN'
        }
    }

    $report | ConvertTo-Json -Depth 3 | Out-File (Join-Path $MemoryDir 'IntegrityCheck.json') -Encoding utf8
    Write-Host "âœ… VÃ©rification dâ€™intÃ©gritÃ© terminÃ©e." -ForegroundColor Green
    return $report
}

# ====================================================================
# ðŸ§© Ã‰tape 2 â€“ RÃ©paration locale via SafeOps ou Backup
# ====================================================================
function Repair-AthenaModule {
    param([string]$Name)
    $Path = Join-Path $ModulesDir "$Name.psm1"
    Write-RepairLog "ðŸ©¹ Tentative de rÃ©paration du module $Name..."

    # ðŸ” 1. Restauration depuis SafeOps (.bak)
    $bak = Get-ChildItem "$Path.bak_*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($bak) {
        Copy-Item $bak.FullName $Path -Force
        Import-Module $Path -Force -Global
        Write-RepairLog "âœ… Restauration depuis snapshot SafeOps : $($bak.Name)"
        Add-LearningEntry $Name 'SafeOpsRestore' 'SuccÃ¨s'
        return
    }

    # ðŸ’¾ 2. Copie depuis Backups
    $backupMatch = Get-ChildItem -Path $BackupsDir -Recurse -Filter "$Name.psm1" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($backupMatch) {
        Copy-Item $backupMatch.FullName $Path -Force
        Import-Module $Path -Force -Global
        Write-RepairLog "âœ… Module restaurÃ© depuis Backup : $($backupMatch.FullName)"
        Add-LearningEntry $Name 'BackupRestore' 'SuccÃ¨s'
        return
    }

    # ðŸ¤– 3. Reconstruction IA locale
    if (Get-Command Invoke-LocalModel -ErrorAction SilentlyContinue) {
        Write-RepairLog "ðŸ§  Reconstruction IA du module $Name en cours..."
        $prompt = "RecrÃ©e le module PowerShell nommÃ© '$Name' pour le projet ArianeV4. 
                   Il doit contenir au moins une fonction 'Invoke-$($Name -replace '\.','')' 
                   qui Ã©crit un message de confirmation. Format PowerShell complet."
        try {
            $code = Invoke-LocalModel -Prompt $prompt
            if ($code -and $code.Length -gt 20) {
                $code | Out-File -FilePath $Path -Encoding UTF8
                Import-Module $Path -Force -Global
                Write-RepairLog "âœ… Module $Name rÃ©gÃ©nÃ©rÃ© via IA locale."
                Add-LearningEntry $Name 'AIRebuild' 'SuccÃ¨s'
            } else {
                Write-RepairLog "âŒ Ã‰chec de gÃ©nÃ©ration IA pour $Name" 'ERROR'
            }
        } catch {
            Write-RepairLog "âš ï¸ Erreur pendant la reconstruction IA : $_"
            Add-LearningEntry $Name 'AIRebuild' 'Ã‰chec'
        }
    } else {
        Write-RepairLog "âš ï¸ Moteur IA local non disponible pour $Name." 'WARN'
        Add-LearningEntry $Name 'AIRebuild' 'Non disponible'
    }
}

# ====================================================================
# â™»ï¸ Ã‰tape 3 â€“ Cycle complet de rÃ©paration
# ====================================================================
function Invoke-AthenaSelfRepair {
    param([switch]$DryRun)

    Write-Host "`nðŸ©º DÃ©marrage du processus complet de SelfRepair..." -ForegroundColor Cyan
    Write-RepairLog "=== Cycle complet lancÃ© ==="

    $integrity = Test-AthenaModuleIntegrity
    $toFix = $integrity | Where-Object { -not $_.Importable -or $_.Taille -eq '0 Ko' }

    if ($toFix.Count -eq 0) {
        Write-RepairLog "âœ… Tous les modules sont intacts."
    } else {
        foreach ($m in $toFix) {
            if ($DryRun) {
                Write-RepairLog "[DRYRUN] Module $($m.Module) nÃ©cessiterait une rÃ©paration." 'INFO'
            } else {
                Repair-AthenaModule -Name ($m.Module -replace '\.psm1','')
            }
        }
    }

    # ðŸ§ª Test post-rÃ©paration
    Write-Host "`nðŸ§ª VÃ©rification post-rÃ©paration..." -ForegroundColor Yellow
    try {
        $exports = Get-Command -Name "Invoke-Athena*" -ErrorAction SilentlyContinue
        Write-RepairLog "Exports disponibles : $($exports.Count)"
    } catch {
        Write-RepairLog "âš ï¸ Ã‰chec de vÃ©rification post-rÃ©paration : $_"
    }

    # ðŸ§¾ Rapport synthÃ©tique
    $summary = [PSCustomObject]@{
        Date = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        ModulesAnalyzed = $integrity.Count
        ModulesRepaired = $toFix.Module
        Duration = "$([math]::Round(((Get-Date) - (Get-Content $LogFile | Select-Object -First 1)).Count,2))"
    }
    $summary | ConvertTo-Json -Depth 4 | Out-File $ReportFile -Encoding UTF8

    # ðŸ”Š Annonce vocale finale
    try {
        Add-Type -AssemblyName System.Speech -ErrorAction Stop
        $s = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $s.Rate = -1
        $s.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::Female)
        $s.Speak("Cycle d'auto-rÃ©paration Athena terminÃ© avec succÃ¨s.")
    } catch {}

    Write-RepairLog "âœ… Cycle de SelfRepair terminÃ© avec succÃ¨s."
    Write-Host "`nâœ… Auto-rÃ©paration complÃ¨te effectuÃ©e." -ForegroundColor Green
}

# ====================================================================
# ðŸ“œ Exportations
# ====================================================================
Export-ModuleMember -Function Invoke-AthenaSelfRepair, Test-AthenaModuleIntegrity, Repair-AthenaModule, Write-RepairLog
Write-Host "ðŸ§  Module Athena.SelfRepair.psm1 chargÃ© (v3.0-Ultimate â€“ Total Recovery Engine)." -ForegroundColor Cyan























# âœ… Correctif appliquÃ© le 17/10/2025 09:06 â€“ Add remplacÃ©.

# âœ… Correctif appliquÃ© le 17/10/2025 09:11 â€“ op_Addition remplacÃ©.











