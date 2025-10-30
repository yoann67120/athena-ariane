# ====================================================================
# ðŸ§  Athena.Signature.psm1 â€“ Gestion des signatures de phases
# --------------------------------------------------------------------
# Version : v1.0â€“PhaseRegistry
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# Objectif :
#   Enregistrer la validation officielle de chaque phase dâ€™Ã©volution
#   dâ€™Athena dans /Memory/Phases.json.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- DÃ©finition des chemins ---
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$MemoryDir  = Join-Path $RootDir "Memory"
$PhasesFile = Join-Path $MemoryDir "Phases.json"
$LogFile    = Join-Path $RootDir "Logs\PhaseSignature.log"

# --- Initialisation des dossiers ---
foreach ($dir in @($MemoryDir, (Join-Path $RootDir "Logs"))) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# --- Fonction de log ---
function Write-SignatureLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# --- VÃ©rifie et initialise le fichier Phases.json ---
if (!(Test-Path $PhasesFile)) {
    @{} | ConvertTo-Json | Out-File $PhasesFile -Encoding utf8BOM
    Write-SignatureLog "CrÃ©ation initiale de Phases.json"
}

# --------------------------------------------------------------------
# ðŸ§© Fonction principale : signature dâ€™une phase
# --------------------------------------------------------------------
function Invoke-AthenaPhaseSignature {
    param(
        [Parameter(Mandatory=$true)][string]$Phase,
        [string]$Status = "ValidÃ©e",
        [string]$Comment = ""
    )

    Write-Host "`nðŸª¶ Enregistrement de la signature de phase : $Phase" -ForegroundColor Cyan

    try {
        # Lecture du fichier Phases.json sous forme de Hashtable
        $data = @{}
        if (Test-Path $PhasesFile) {
            $jsonContent = Get-Content $PhasesFile -Raw
            if ($jsonContent.Trim().Length -gt 0) {
                $tmp = $jsonContent | ConvertFrom-Json
                if ($tmp -is [System.Collections.Hashtable]) {
                    $data = $tmp
                } else {
                    # Convertit l'objet PSCustomObject en Hashtable
                    $data = @{}
                    $tmp.PSObject.Properties | ForEach-Object {
                        $data[$_.Name] = $_.Value
                    }
                }
            }
        }

        # PrÃ©pare l'entrÃ©e Ã  ajouter
        $entry = @{
            "Phase"       = "Phase $Phase"
            "Statut"      = $Status
            "Date"        = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            "Commentaire" = $Comment
        }

        # Ajout / mise Ã  jour
        $data["Phase $Phase"] = $entry

        # Sauvegarde du JSON
        $data | ConvertTo-Json -Depth 5 | Out-File $PhasesFile -Encoding utf8BOM

        Write-Host "âœ… Phase $Phase enregistrÃ©e comme '$Status'" -ForegroundColor Green
        Write-SignatureLog "[OK] Phase $Phase enregistrÃ©e comme '$Status'"
    }
    catch {
        Write-Host "âŒ Erreur lors de l'enregistrement de la phase : $_" -ForegroundColor Red
        Write-SignatureLog "[ERROR] Enregistrement Ã©chouÃ© : $_"
    }
}

# --------------------------------------------------------------------
# ðŸ§© Fonction complÃ©mentaire : afficher les phases validÃ©es
# --------------------------------------------------------------------
function Get-AthenaPhaseHistory {
    if (Test-Path $PhasesFile) {
        $data = Get-Content $PhasesFile -Raw | ConvertFrom-Json
        Write-Host "`nðŸ“œ Historique des phases validÃ©es :" -ForegroundColor Yellow
        foreach ($key in $data.PSObject.Properties.Name) {
            $item = $data.$key
            Write-Host (" - {0} â†’ {1} ({2})" -f $item.Phase, $item.Statut, $item.Date) -ForegroundColor Green
        }
    } else {
        Write-Host "âš ï¸ Aucun historique de phases trouvÃ©." -ForegroundColor Yellow
    }
}

# --------------------------------------------------------------------
# ðŸ”š Export des fonctions
# --------------------------------------------------------------------
Export-ModuleMember -Function Invoke-AthenaPhaseSignature, Get-AthenaPhaseHistory

Write-Host "ðŸ§  Module Athena.Signature.psm1 chargÃ© (v1.0â€“PhaseRegistry)" -ForegroundColor Cyan
Write-SignatureLog "Module chargÃ© (v1.0â€“PhaseRegistry)"



