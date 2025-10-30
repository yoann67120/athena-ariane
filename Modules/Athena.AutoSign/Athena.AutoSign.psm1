# ====================================================================
# ðŸ¤– Athena.AutoSign.psm1 â€“ Signature automatique des phases
# --------------------------------------------------------------------
# Version : v1.0â€“AutoPhaseSync
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# Objectif :
#   Permet Ã  Athena de signer automatiquement toute phase validÃ©e.
#   DÃ©tection, lecture des logs, et mise Ã  jour de /Memory/Phases.json.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$PhasesFile = Join-Path $MemoryDir "Phases.json"
$SignatureModule = Join-Path $ModuleRoot "Athena.Signature.psm1"
$LogFile    = Join-Path $LogsDir "AutoSign.log"

foreach ($dir in @($MemoryDir, $LogsDir)) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# --------------------------------------------------------------------
# ðŸª¶ Fonction de log
# --------------------------------------------------------------------
function Write-AutoSignLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# --------------------------------------------------------------------
# ðŸ” Fonction principale
# --------------------------------------------------------------------
function Invoke-AthenaAutoSign {
    param(
        [Parameter(Mandatory=$true)][string]$PhaseNumber,
        [Parameter(Mandatory=$true)][string]$CheckScriptName
    )

    Write-Host "`nðŸ¤– VÃ©rification automatique de la phase $PhaseNumber..." -ForegroundColor Cyan
    Write-AutoSignLog "Analyse du script $CheckScriptName"

    $ReportFile = Join-Path $LogsDir "PhaseValidation.log"

    if (!(Test-Path $ReportFile)) {
        Write-Host "âš ï¸ Aucun fichier PhaseValidation.log trouvÃ© â€“ impossible de signer." -ForegroundColor Yellow
        Write-AutoSignLog "[WARN] Aucun rapport trouvÃ© pour la phase $PhaseNumber"
        return
    }

    # Lecture du rapport
    $content = Get-Content $ReportFile -Raw
    if ($content -match "VALIDEE AVEC SUCCES") {
        Write-Host "âœ… Phase $PhaseNumber dÃ©tectÃ©e comme validÃ©e. Initialisation de la signature..." -ForegroundColor Green

        # Import du module de signature
        if (Test-Path $SignatureModule) {
            Import-Module $SignatureModule -Force -Global

            $comment = "Validation automatique dÃ©tectÃ©e via $CheckScriptName"
            Invoke-AthenaPhaseSignature -Phase $PhaseNumber -Status "ValidÃ©e âœ”" -Comment $comment
            Write-Host "ðŸ§  Signature automatique effectuÃ©e avec succÃ¨s pour la phase $PhaseNumber." -ForegroundColor Green
            Write-AutoSignLog "[OK] Phase $PhaseNumber signÃ©e automatiquement."
        } else {
            Write-Host "âŒ Module Athena.Signature.psm1 introuvable â€“ signature annulÃ©e." -ForegroundColor Red
            Write-AutoSignLog "[ERROR] Module de signature manquant."
        }
    }
    else {
        Write-Host "âš™ï¸ Phase $PhaseNumber non validÃ©e â€“ aucune signature effectuÃ©e." -ForegroundColor Yellow
        Write-AutoSignLog "[INFO] Phase $PhaseNumber non validÃ©e."
    }
}

# --------------------------------------------------------------------
# ðŸ§¾ Fonction complÃ©mentaire : liste les signatures existantes
# --------------------------------------------------------------------
function Get-AutoSignHistory {
    if (Test-Path $PhasesFile) {
        $json = Get-Content $PhasesFile -Raw | ConvertFrom-Json
        Write-Host "`nðŸ“œ Historique des signatures automatiques :" -ForegroundColor Yellow
        foreach ($k in $json.PSObject.Properties.Name) {
            $item = $json.$k
            Write-Host (" - {0} : {1} ({2})" -f $item.Phase, $item.Statut, $item.Date) -ForegroundColor Green
        }
    } else {
        Write-Host "âš ï¸ Aucun historique trouvÃ©." -ForegroundColor Yellow
    }
}

# --------------------------------------------------------------------
# ðŸ”š Export des fonctions
# --------------------------------------------------------------------
Export-ModuleMember -Function Invoke-AthenaAutoSign, Get-AutoSignHistory
Write-Host "ðŸ¤– Module Athena.AutoSign.psm1 chargÃ© (v1.0â€“AutoPhaseSync)" -ForegroundColor Cyan
Write-AutoSignLog "Module chargÃ© (v1.0â€“AutoPhaseSync)"



