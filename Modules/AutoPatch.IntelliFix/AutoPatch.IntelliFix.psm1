# ====================================================================
# ðŸ§  AutoPatch.IntelliFix.psm1 â€“ Diagnostic et correction intelligente
# Version : v1.0-Stable
# Auteur   : Projet Ariane V4 / Athena
# Objectif : Ã‰tendre AutoPatch avec une analyse contextuelle et logique.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$PatternsDB = Join-Path $MemoryDir "AutoFixPatterns.json"
$ReportFile = Join-Path $LogsDir "IntelliFix.log"

if (!(Test-Path $LogsDir))   { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null }

function Write-IntelliFixLog {
    param([string]$Msg,[string]$L="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $ReportFile -Value "[$t][$L] $Msg"
}

# ====================================================================
# ðŸ” Ã‰tape 1 â€“ Analyse logique du code PowerShell
# ====================================================================
function Test-ModuleIntegrity {
    param([string]$Path)
    if (!(Test-Path $Path)) { return $null }

    $code = Get-Content $Path -Raw
    $report = [ordered]@{
        Path = $Path
        MissingImports = @()
        LogicWarnings  = @()
    }

    # VÃ©rifie prÃ©sence de sections essentielles
    if ($code -notmatch "Import-Module") {
        $report.MissingImports += "Aucun Import-Module dÃ©tectÃ©."
    }
    if ($code -match "Invoke-LocalModel" -and $code -notmatch "Import-Module.*LocalModel") {
        $report.LogicWarnings  += "Utilisation d'Invoke-LocalModel sans import explicite de LocalModel.psm1"
    }
    if ($code -match "Invoke-ActionPlan" -and $code -notmatch "Import-Module.*ActionEngine") {
        $report.LogicWarnings  += "Appel de Invoke-ActionPlan sans import du module ActionEngine.psm1"
    }
    if ($code -match "Invoke-AthenaPersona" -and $code -notmatch "Import-Module.*Athena.Persona") {
        $report.LogicWarnings  += "Appel d'Invoke-AthenaPersona sans import du module Athena.Persona.psm1"
    }

    return $report
}

# ====================================================================
# ðŸ§© Ã‰tape 2 â€“ GÃ©nÃ©ration et application du correctif
# ====================================================================
function Invoke-IntelliFix {
    param(
        [string]$Path,
        [switch]$AutoFix
    )

    if (!(Test-Path $Path)) {
        Write-Warning "âŒ Fichier introuvable : $Path"
        return
    }

    $diagnostic = Test-ModuleIntegrity -Path $Path
    if (-not $diagnostic) { return }

    $hasIssue = ($diagnostic.LogicWarnings.Count -gt 0 -or $diagnostic.MissingImports.Count -gt 0)
    if (-not $hasIssue) {
        Write-Host "âœ… Aucun problÃ¨me logique dÃ©tectÃ© dans $($diagnostic.Path)" -ForegroundColor Green
        Write-IntelliFixLog "Aucun problÃ¨me dÃ©tectÃ© dans $($diagnostic.Path)"
        return
    }

    Write-Host "`nðŸ§© Diagnostic pour $($diagnostic.Path)" -ForegroundColor Yellow
    foreach ($warn in $diagnostic.LogicWarnings) { Write-Host "âš ï¸ $warn" -ForegroundColor Yellow }

    if (-not $AutoFix) {
        $choice = Read-Host "Souhaitez-vous appliquer automatiquement les corrections proposÃ©es ? (O/N)"
        if ($choice -notin @("O","o","Y","y")) {
            Write-Host "ðŸš« Aucune correction appliquÃ©e."
            return
        }
    }

    $code = Get-Content $Path -Raw
    $backup = "$Path.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
    Copy-Item $Path $backup -Force
    Write-IntelliFixLog "Sauvegarde avant correction : $backup"

    # --- Exemple : insertion automatique des imports manquants ---
    if ($diagnostic.LogicWarnings -match "LocalModel") {
        $code = $code -replace '(# === Dossiers principaux)', "`$0`nImport-Module (Join-Path `$ModulesDir 'LocalModel.psm1') -Force -Global | Out-Null"
    }
    if ($diagnostic.LogicWarnings -match "ActionEngine") {
        $code = $code -replace '(# === Dossiers principaux)', "`$0`nImport-Module (Join-Path `$ModulesDir 'ActionEngine.psm1') -Force -Global | Out-Null"
    }
    if ($diagnostic.LogicWarnings -match "Athena.Persona") {
        $code = $code -replace '(# === Dossiers principaux)', "`$0`nImport-Module (Join-Path `$ModulesDir 'Athena.Persona.psm1') -Force -Global | Out-Null"
    }

    # Sauvegarde du code corrigÃ©
    Set-Content -Path $Path -Value $code -Encoding UTF8
    Write-Host "âœ… Correctif appliquÃ© Ã  $Path (sauvegarde : $backup)" -ForegroundColor Green
    Write-IntelliFixLog "Correctif appliquÃ© Ã  $Path"
}

# ====================================================================
# ðŸ§  Ã‰tape 3 â€“ Boucle dâ€™apprentissage simple
# ====================================================================
function Save-AutoFixPattern {
    param([string]$Pattern,[string]$Correction)
    $patterns = @()
    if (Test-Path $PatternsDB) { $patterns = Get-Content $PatternsDB | ConvertFrom-Json }
    $patterns += [PSCustomObject]@{ Pattern=$Pattern; Correction=$Correction; Date=(Get-Date) }
    $patterns | ConvertTo-Json -Depth 5 | Set-Content -Path $PatternsDB -Encoding UTF8
    Write-IntelliFixLog "Nouveau pattern AutoFix ajoutÃ© : $Pattern"
}

# ====================================================================
# ðŸš€ IntÃ©gration au cycle AutoPatch principal
# ====================================================================
function Invoke-AutoPatchIntelliFix {
    param([string]$TargetDir = (Join-Path $RootDir "Modules"))
    Write-Host "`nðŸ§  Lancement d'AutoPatch IntelliFix sur $TargetDir..." -ForegroundColor Cyan

    $modules = Get-ChildItem $TargetDir -Filter *.psm1 -Recurse
    foreach ($m in $modules) {
        $report = Test-ModuleIntegrity -Path $m.FullName
        if ($report.LogicWarnings.Count -gt 0) {
            Write-Host "ðŸ” Analyse : $($m.Name) â†’ $($report.LogicWarnings.Count) problÃ¨me(s) dÃ©tectÃ©(s)"
            Invoke-IntelliFix -Path $m.FullName -AutoFix
        }
    }
    Write-Host "âœ… AutoPatch IntelliFix terminÃ©." -ForegroundColor Green
}

# ====================================================================
# ðŸ“¤ Export global
# ====================================================================
Export-ModuleMember -Function `
    Invoke-IntelliFix, Test-ModuleIntegrity, Invoke-AutoPatchIntelliFix, Save-AutoFixPattern

Write-Host "âœ… Module AutoPatch.IntelliFix.psm1 v1.0 chargÃ© (analyse contextuelle active)." -ForegroundColor Cyan



