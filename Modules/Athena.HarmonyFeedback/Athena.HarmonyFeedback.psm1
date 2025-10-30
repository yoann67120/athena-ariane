# ====================================================================
# ðŸŽ¨ Athena.HarmonyFeedback.psm1 â€“ Signaux visuels, sonores et vocaux
# Version : v1.0-Feedback-Stable
# Auteur  : Athena Core Engine / Ariane V4
# ====================================================================
# Objectif :
#   - GÃ©rer la rÃ©troaction visuelle et sonore du cockpit
#   - Transmettre messages vocaux selon Ã©tat Ã©motionnel
#   - Maintenir cohÃ©rence entre indicateurs et Ã©tat interne
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$LogFile    = Join-Path $LogsDir "AthenaHarmonyFeedback.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-FeedbackLog {
    param([string]$Message,[string]$Level="INFO")
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level] $Message"
}

# ðŸ”¹ Mise Ã  jour du cockpit (barres, couleurs, indicateurs)
function Show-HarmonyStatusCockpit {
    param([string]$Etat,[int]$Indice)
    $color = switch -regex ($Etat) {
        "SÃ©rÃ©nitÃ©" { "Blue" }
        "Ã‰quilibre" { "Cyan" }
        "Alerte" { "Yellow" }
        "Stress" { "Red" }
        default { "Gray" }
    }
    Write-Host "ðŸŽ›ï¸ Cockpit â†’ $Etat ($Indice%)" -ForegroundColor $color
    Write-FeedbackLog "Cockpit mis Ã  jour : $Etat ($Indice%)"
}

# ðŸ”¹ Sonorisation selon Ã©tat
function Play-HarmonySound {
    param([string]$Etat)
    try {
        $soundPath = Join-Path $RootDir "Assets\Sounds\$Etat.wav"
        if (Test-Path $soundPath) {
            (New-Object Media.SoundPlayer $soundPath).Play()
            Write-FeedbackLog "Son jouÃ© : $soundPath"
        } else {
            Write-FeedbackLog "Aucun son trouvÃ© pour $Etat"
        }
    } catch { Write-Warning "Erreur audio : $_" }
}

# ðŸ”¹ Message vocal (TTS)
function Speak-HarmonyMessage {
    param([string]$Message)
    try {
        Add-Type -AssemblyName System.Speech
        $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $synth.Rate = 0
        $synth.Volume = 90
        $synth.Speak($Message)
        Write-FeedbackLog "Message vocal : $Message"
    } catch { Write-Warning "Erreur TTS : $_" }
}

# ðŸ”¹ Notification locale
function Send-LocalNotification {
    param([string]$Message)
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($Message,"Athena Harmony","OK","Information")
        Write-FeedbackLog "Notification affichÃ©e : $Message"
    } catch { Write-Warning "Notification Ã©chouÃ©e : $_" }
}

# ðŸ”¹ RÃ©initialisation cockpit
function Force-CockpitReset {
    param([switch]$Confirm)
    if (-not $Confirm) {
        Write-Host "âš ï¸ Utiliser -Confirm pour rÃ©initialiser le cockpit."
        return
    }
    Write-FeedbackLog "Cockpit rÃ©initialisÃ© manuellement."
    Write-Host "ðŸ” Cockpit remis Ã  zÃ©ro." -ForegroundColor Cyan
}

Export-ModuleMember -Function Show-HarmonyStatusCockpit,Play-HarmonySound,Speak-HarmonyMessage,Send-LocalNotification,Force-CockpitReset
Write-Host "ðŸŽ¨ Module Athena.HarmonyFeedback.psm1 chargÃ© (v1.0-Feedback-Stable)." -ForegroundColor Cyan



