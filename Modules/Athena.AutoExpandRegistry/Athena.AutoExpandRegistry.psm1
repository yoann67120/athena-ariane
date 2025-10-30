# ====================================================================
# ðŸ§  Athena.AutoExpandRegistry.psm1 â€“ v1.0-LearningKeys-Evo
# --------------------------------------------------------------------
# Objectif :
#   Analyse les contextes rÃ©cemment utilisÃ©s par Athena.IntegrationAdvisor
#   et ajoute automatiquement les mots-clÃ©s manquants dans le registre
#   OpenSourceRegistry.json.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === RÃ©pertoires et fichiers ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ConfigDir  = Join-Path $RootDir "Config"
$Registry   = Join-Path $ConfigDir "OpenSourceRegistry.json"
$BackupDir  = Join-Path $MemoryDir "Archives\Registry"
$LogFile    = Join-Path $LogsDir "RegistryExpansion.log"

foreach ($p in @($LogsDir, $MemoryDir, $ConfigDir, $BackupDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# === Journal interne ===
function Write-RegistryLog {
    param([string]$Msg, [string]$Level = "INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# === 1ï¸âƒ£ Lecture du registre ===
function Get-Registry {
    if (!(Test-Path $Registry)) {
        Write-RegistryLog "âŒ Registre introuvable : $Registry" "ERROR"
        return $null
    }
    try {
        return Get-Content $Registry -Raw | ConvertFrom-Json
    } catch {
        Write-RegistryLog "âŒ Erreur de parsing JSON : $_" "ERROR"
        return $null
    }
}

# === 2ï¸âƒ£ DÃ©tection des mots manquants ===
function Detect-MissingKeywords {
    param([string[]]$Contexts)

    $reg = Get-Registry
    if ($null -eq $reg) { return }

    Write-RegistryLog "Analyse de $($Contexts.Count) contexte(s)."

    $added = @()
    foreach ($ctx in $Contexts) {
        Write-RegistryLog "Contexte : $ctx"

        # DÃ©coupe les mots significatifs
        $words = $ctx.ToLower() -split '\s+'
        foreach ($section in $reg.PSObject.Properties.Name) {
            foreach ($tool in $reg.$section.PSObject.Properties.Name) {
                $entry = $reg.$section.$tool
                foreach ($w in $words) {
                    if ($w.Length -ge 4 -and $entry.keywords -notcontains $w) {
                        # Apprentissage : ajoute un mot nouveau si proche du type
                        if ($w -match $entry.type -or $w -match $section -or $ctx -match $entry.type) {
                            $entry.keywords += $w
                            $added += "$tool â†’ +$w"
                            Write-RegistryLog "ðŸ§© Ajout du mot-clÃ© '$w' Ã  $tool"
                        }
                    }
                }
            }
        }
    }

    # Sauvegarde seulement si des ajouts ont Ã©tÃ© faits
    if ($added.Count -gt 0) {
        $backup = Join-Path $BackupDir ("Backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")
        Copy-Item $Registry $backup -Force
        Write-RegistryLog "Sauvegarde de l'ancien registre : $backup"

        $reg | ConvertTo-Json -Depth 6 | Out-File $Registry -Encoding utf8
        Write-RegistryLog "âœ… Registre enrichi automatiquement ($($added.Count) ajouts)."
    } else {
        Write-RegistryLog "Aucun nouveau mot-clÃ© dÃ©tectÃ©."
    }

    return $added
}

# === 3ï¸âƒ£ Interface principale ===
function Invoke-AutoExpandRegistry {
    param([string[]]$Contexts)

    Write-Host "`nðŸ§  Lancement de l'expansion automatique du registre..." -ForegroundColor Cyan
    Write-RegistryLog "=== DÃ©marrage AutoExpand ==="

    $result = Detect-MissingKeywords -Contexts $Contexts

    if ($result.Count -gt 0) {
        Write-Host "âœ… $($result.Count) mot(s)-clÃ©(s) ajoutÃ©(s) :" -ForegroundColor Green
        $result | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    } else {
        Write-Host "â„¹ï¸ Aucun ajout nÃ©cessaire." -ForegroundColor Yellow
    }

    Write-RegistryLog "=== Fin AutoExpand ==="
}

# === Export public ===
Export-ModuleMember -Function Invoke-AutoExpandRegistry, Detect-MissingKeywords
Write-Host "ðŸ§  Module Athena.AutoExpandRegistry.psm1 chargÃ© (v1.0-LearningKeys-Evo)." -ForegroundColor Cyan



