# ====================================================================
# ðŸ§  Athena.IntentParser.psm1 â€“ v1.1-CognitiveBridge-Fix
# Phase 35 â€“ Pont cognitif entre langage naturel et modules internes
# Auteur : Projet Ariane V4 / Athena Core
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Dossiers principaux -------------------------------------------------
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$IntentLog  = Join-Path $LogsDir "IntentParser.log"
$IntentMem  = Join-Path $MemoryDir "IntentHistory.json"

foreach ($p in @($LogsDir,$MemoryDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# ====================================================================
# âœï¸ Fonction de log
# ====================================================================
function Write-IntentLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $IntentLog -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ§© Analyse linguistique basique
# ====================================================================
function Parse-Intent {
    param([string]$Commande)

    $intent = [ordered]@{
        Texte       = $Commande
        CatÃ©gorie   = "Inconnue"
        Moteur      = "Aucun"
        Confiance   = 0.0
        DÃ©tection   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    try {
        $lower = $Commande.ToLower()
        $clean = ($lower -replace '[Ã©Ã¨ÃªÃ«]', 'e')

        switch -Regex ($clean) {
            "cree|creation|nouveau|genere|lance un projet" {
                $intent.CatÃ©gorie = "CrÃ©ation de projet"
                $intent.Moteur = "ProjectManager"
                $intent.Confiance = 0.95
            }
            "analyse|verifie|diagnostic|controle" {
                $intent.CatÃ©gorie = "Analyse systÃ¨me"
                $intent.Moteur = "SelfCoordinator"
                $intent.Confiance = 0.9
            }
            "repare|corrige|restore|reinstalle" {
                $intent.CatÃ©gorie = "RÃ©paration"
                $intent.Moteur = "AutoDeploy"
                $intent.Confiance = 0.9
            }
            "apprend|learning|ameliore|etudie" {
                $intent.CatÃ©gorie = "Apprentissage"
                $intent.Moteur = "AutoLearning"
                $intent.Confiance = 0.9
            }
            "sauvegarde|backup|archive" {
                $intent.CatÃ©gorie = "Sauvegarde"
                $intent.Moteur = "AutoDeploy"
                $intent.Confiance = 0.9
            }
            "etat|status|humeur|emotion" {
                $intent.CatÃ©gorie = "Ã‰tat interne"
                $intent.Moteur = "SelfAwareness"
                $intent.Confiance = 0.85
            }
            "cockpit|interface|affiche|ouvre" {
                $intent.CatÃ©gorie = "Interface / Cockpit"
                $intent.Moteur = "Cockpit.Server"
                $intent.Confiance = 0.9
            }
            default {
                $intent.CatÃ©gorie = "Inconnue"
                $intent.Moteur = "Aucun"
                $intent.Confiance = 0.3
            }
        }

        Write-IntentLog "ðŸ§  Intent dÃ©tectÃ© : $($intent.CatÃ©gorie) (Moteur=$($intent.Moteur), Confiance=$($intent.Confiance))"
        return $intent
    }
    catch {
        Write-IntentLog "âŒ Erreur analyse d'intention : $_" "ERROR"
        return $intent
    }
}


# ====================================================================
# ðŸª¶ Stockage mÃ©moire
# ====================================================================
function Save-Intent {
    param([hashtable]$Intent)
    try {
        $history = @()
        if (Test-Path $IntentMem) {
            $history = Get-Content $IntentMem -Raw | ConvertFrom-Json
        }
        $history += $Intent
        $history | ConvertTo-Json -Depth 4 | Out-File $IntentMem -Encoding utf8
    } catch {
        Write-IntentLog "âŒ Erreur sauvegarde : $_" "ERROR"
    }
}

# ====================================================================
# ðŸš€ EntrÃ©e principale â€“ InterprÃ©tation et routage
# ====================================================================
function Invoke-AthenaIntentParser {
    param([string]$Commande)

    Write-Host "`nðŸ—£ï¸ Analyse de la commande : $Commande" -ForegroundColor Cyan
    $intent = Parse-Intent -Input $Commande
    Save-Intent -Intent $intent

    switch ($intent.Moteur) {
        "ProjectManager" {
            if (Get-Command Invoke-AthenaProjectManager -ErrorAction SilentlyContinue) {
                Invoke-AthenaProjectManager -Commande $Commande
            } else {
                Write-Host "ðŸ“¦ Module ProjectManager non encore chargÃ©. (Phase suivante)" -ForegroundColor Yellow
            }
        }
        "SelfCoordinator" {
            Invoke-AthenaCoordinationCycle
        }
        "AutoDeploy" {
            Invoke-AthenaAutoDeploy
        }
        "AutoLearning" {
            Invoke-AthenaAutoLearning
        }
        "SelfAwareness" {
            Invoke-AthenaSelfAwareness
        }
        "Cockpit.Server" {
            if (Get-Command Start-CockpitServer -ErrorAction SilentlyContinue) {
                Start-CockpitServer
            } else {
                Write-Host "ðŸŒ Le module Cockpit.Server n'est pas actif actuellement." -ForegroundColor Yellow
            }
        }
        default {
            Write-Host "ðŸ¤” Aucune action directe dÃ©tectÃ©e." -ForegroundColor DarkGray
        }
    }

    Write-Host "âœ… Analyse terminÃ©e. (Intention : $($intent.CatÃ©gorie))" -ForegroundColor Green
}

# ====================================================================
# ðŸ”š Exportation des fonctions
# ====================================================================
Export-ModuleMember -Function Invoke-AthenaIntentParser, Parse-Intent, Save-Intent
Write-Host "ðŸ§© Module Athena.IntentParser.psm1 chargÃ© (v1.1-CognitiveBridge-Fix)." -ForegroundColor Cyan


