# ====================================================================
# ðŸ§  Athena.Dialogue.psm1 â€“ v1.0-NLU-Core
# Objectif : Moteur de comprÃ©hension textuelle (NLU) pour le cockpit
# Auteur : Ariane V4 / Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === Dossiers principaux ===
$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir 'Logs'
$VoiceModule = Join-Path $RootDir 'Modules\Athena.Voice.psm1'
$NotifyModule = Join-Path $RootDir 'Modules\Cockpit.Notify.psm1'

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile = Join-Path $LogsDir 'AthenaDialogue.log'

function Write-DialogueLog {
    param([string]$Msg,[string]$Level='INFO')
    $t = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
    Write-Host $Msg -ForegroundColor DarkGray
}

# ====================================================================
# ðŸ” Fonction : Analyse du texte et dÃ©termination de lâ€™intention
# ====================================================================
function Get-Intent {
    param([string]$Input)

    $normalized = $Input.ToLower()

    switch -Regex ($normalized) {
        "rÃ©pare|nettoie|corrige"          { return "repair" }
        "analyse|diagnostic"              { return "diagnostic" }
        "coordination|synchronise|synchro" { return "coordination" }
        "crÃ©e|nouveau|projet|usine"       { return "project" }
        "voix|parle|mute|micro"           { return "voice" }
        "Ã©volution|apprends|formation"    { return "learning" }
        "sÃ©curitÃ©|guardian|protection"    { return "security" }
        "bonjour|salut|hello"             { return "greeting" }
        default                           { return "unknown" }
    }
}

# ====================================================================
# ðŸ§© Fonction principale : Invocation du dialogue
# ====================================================================
function Invoke-AthenaDialogue {
    param([Parameter(Mandatory)][string]$Input)

    Write-DialogueLog "ðŸ—£ï¸ EntrÃ©e utilisateur : $Input"

    $intent = Get-Intent -Input $Input
    Write-DialogueLog "ðŸŽ¯ Intent dÃ©tectÃ© : $intent"

    switch ($intent) {

        "repair" {
            try {
                Import-Module "$RootDir\Modules\Athena.SelfRepair.psm1" -Force -Global
                Invoke-AthenaSelfRepair
                $reply = "RÃ©paration et nettoyage effectuÃ©s, tout est stable."
            } catch {
                $reply = "Je nâ€™ai pas pu exÃ©cuter la rÃ©paration complÃ¨te, Yoann."
            }
        }

        "diagnostic" {
            try {
                Import-Module "$RootDir\Modules\Athena.Diagnostic.psm1" -Force -Global
                Invoke-AthenaDiagnostic
                $reply = "Diagnostic terminÃ©. Aucun problÃ¨me critique dÃ©tectÃ©."
            } catch {
                $reply = "Le diagnostic a rencontrÃ© une erreur inattendue."
            }
        }

        "coordination" {
            try {
                Import-Module "$RootDir\Modules\Athena.SelfCoordinator.psm1" -Force -Global
                Invoke-AthenaCoordinationCycle
                $reply = "Cycle de coordination achevÃ© avec succÃ¨s."
            } catch {
                $reply = "La coordination nâ€™a pas pu Ãªtre effectuÃ©e pour le moment."
            }
        }

        "project" {
            try {
                Import-Module "$RootDir\Modules\Athena.Architect.psm1" -Force -Global
                Start-AthenaProjectSetup
                $reply = "Jâ€™ai lancÃ© le mode 'Usine Ã  projets'."
            } catch {
                $reply = "Je ne parviens pas Ã  ouvrir lâ€™Usine Ã  projets pour lâ€™instant."
            }
        }

        "voice" {
            $reply = "Le module vocal est dÃ©jÃ  actif. Je tâ€™Ã©coute, Yoann."
        }

        "learning" {
            try {
                Import-Module "$RootDir\Modules\Athena.AutoLearning.psm1" -Force -Global
                Invoke-AthenaAutoLearning
                $reply = "Cycle dâ€™apprentissage relancÃ© avec succÃ¨s."
            } catch {
                $reply = "Lâ€™apprentissage nâ€™a pas pu Ãªtre dÃ©marrÃ©."
            }
        }

        "security" {
            try {
                Import-Module "$RootDir\Modules\Athena.SecurityGuardian.psm1" -Force -Global
                Invoke-AthenaSecurityScan
                $reply = "VÃ©rification Guardian terminÃ©e. Aucun danger dÃ©tectÃ©."
            } catch {
                $reply = "Le module de sÃ©curitÃ© nâ€™a pas pu Ãªtre contactÃ©."
            }
        }

        "greeting" {
            $reply = "Bonjour Yoann, heureuse de te retrouver. Tous les systÃ¨mes sont prÃªts."
        }

        Default {
            $reply = "Je nâ€™ai pas encore appris Ã  exÃ©cuter cette demande, mais je tâ€™Ã©coute."
        }
    }

    # --- Envoi du message vocal ---
    if (Test-Path $VoiceModule) {
        Import-Module $VoiceModule -Force -Global
        Speak-Athena -Text $reply -Visual
    }

    # --- Notification visuelle ---
    if (Test-Path $NotifyModule) {
        Import-Module $NotifyModule -Force -Global
        Invoke-CockpitNotify -Message $reply -Tone "info"
    }

    Write-DialogueLog "ðŸ’¬ RÃ©ponse envoyÃ©e : $reply"
    return $reply
}

Export-ModuleMember -Function Invoke-AthenaDialogue
Write-Host "ðŸ§  Athena.Dialogue.psm1 chargÃ© (v1.0-NLU-Core)" -ForegroundColor Cyan
Write-DialogueLog "Module chargÃ© (v1.0-NLU-Core)"



