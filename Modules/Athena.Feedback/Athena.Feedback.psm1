# =====================================================================
# ðŸ«€ Athena.Feedback.psm1 â€“ SystÃ¨me Sensoriel et dâ€™Humeur (v2.1-stable)
# =====================================================================
# Objectif :
#   - Lire le dernier rapport cognitif dâ€™Athena
#   - Extraire Observation / HypothÃ¨se / Action_suggÃ©rÃ©e
#   - Produire une rÃ©ponse sensorielle (voix, son, cockpit)
#   - Enregistrer le feedback dans Logs\Athena.Feedback.log
# =====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir "Logs"
$Report    = Join-Path $LogsDir "Athena.CognitiveReport.log"
$FeedbackLog = Join-Path $LogsDir "Athena.Feedback.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-FeedbackLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $FeedbackLog -Value "[$t] $Msg"
}

# ---------------------------------------------------------------------
# Lecture et extraction des Ã©lÃ©ments du dernier rapport cognitif
# ---------------------------------------------------------------------
function Get-LastReflection {
    if (!(Test-Path $Report)) {
        Write-FeedbackLog "Aucun rapport cognitif trouvÃ©."
        return @{
            Observation = "Aucune observation disponible."
            Hypothese   = "Aucune hypothÃ¨se dÃ©tectÃ©e."
            Action      = "Aucune action suggÃ©rÃ©e."
        }
    }

    try {
        $lines = Get-Content $Report -ErrorAction Stop
        # On recherche les trois sections principales avec des correspondances souples
        $observation = ($lines | Where-Object { $_ -match 'Observation\s*[:\-]' } | Select-Object -Last 1) -replace '.*[:\-]\s*',''
        $hypothese   = ($lines | Where-Object { $_ -match 'Hypoth[eÃ¨]se\s*[:\-]' } | Select-Object -Last 1) -replace '.*[:\-]\s*',''
        $action      = ($lines | Where-Object { $_ -match 'Action(_suggeree| suggÃ©rÃ©e)?\s*[:\-]' } | Select-Object -Last 1) -replace '.*[:\-]\s*',''

        if ([string]::IsNullOrWhiteSpace($observation)) { $observation = "Non spÃ©cifiÃ©e." }
        if ([string]::IsNullOrWhiteSpace($hypothese))   { $hypothese   = "Non spÃ©cifiÃ©e." }
        if ([string]::IsNullOrWhiteSpace($action))      { $action      = "Non spÃ©cifiÃ©e." }

        return @{
            Observation = $observation.Trim()
            Hypothese   = $hypothese.Trim()
            Action      = $action.Trim()
        }
    }
    catch {
        Write-FeedbackLog "Erreur de lecture du rapport cognitif : $_"
        return @{
            Observation = "Erreur de lecture."
            Hypothese   = "Erreur."
            Action      = "Erreur."
        }
    }
}

# ---------------------------------------------------------------------
# Analyse du rapport et restitution sensorielle
# ---------------------------------------------------------------------
function Invoke-AthenaFeedback {
    Write-Host "`nðŸ“£ DÃ©clenchement du module Athena.Feedback..." -ForegroundColor Cyan
    $data = Get-LastReflection
    $obs = $data.Observation
    $hyp = $data.Hypothese
    $act = $data.Action

    Write-FeedbackLog "Observation=$obs | Hypothese=$hyp | Action=$act"

    # DÃ©termination dâ€™Ã©tat selon lâ€™action
    $state = "SÃ©rÃ©nitÃ©"
    $mood  = "satisfaite"
    $message = "Tout semble stable. Je poursuis sereinement mon observation."

    if ($act -match 'repar|corrig|instabil|surveill') {
        $state = "Concentration"
        $mood  = "attentive"
        $message = "InstabilitÃ© dÃ©tectÃ©e, je reste concentrÃ©e."
    }
    elseif ($act -match 'erreur|anomal|probleme|defaut') {
        $state = "Vigilance"
        $mood  = "inquiÃ¨te"
        $message = "Anomalie identifiÃ©e, je garde un Å“il attentif."
    }
    elseif ($act -match 'optimis|amÃ©lior|stabilis') {
        $state = "SÃ©rÃ©nitÃ©"
        $mood  = "satisfaite"
        $message = "Situation maÃ®trisÃ©e, je poursuis calmement."
    }

    # --- Cockpit visuel ---
    if (Get-Command Set-CockpitMood -ErrorAction SilentlyContinue) {
        Set-CockpitMood -Mood $mood -State $state -Message $message
    }

    # --- Son ---
    if (Get-Command Play-AthenaSound -ErrorAction SilentlyContinue) {
        Play-AthenaSound -Mood $mood -State $state
    }

    # --- Voix ---
    if (Get-Command Invoke-AthenaVoice -ErrorAction SilentlyContinue) {
        Invoke-AthenaVoice -Text $message -Silent
    }

    # Log final
    Write-FeedbackLog "Etat=$state | Humeur=$mood | Message=$message"
    Write-Host "ðŸŽ›ï¸ Cockpit : Ã©tat=$state | humeur=$mood" -ForegroundColor Yellow
    Write-Host "ðŸ“¡ $message" -ForegroundColor Green
    Write-Host "ðŸ“ Feedback enregistrÃ© dans $FeedbackLog" -ForegroundColor Gray
}

Export-ModuleMember -Function Invoke-AthenaFeedback, Get-LastReflection
Write-Host "ðŸ«€ Module Athena.Feedback chargÃ© (v2.1-CognitiveHarmony-Stable)." -ForegroundColor Cyan
Write-FeedbackLog "Module chargÃ© (v2.1-CognitiveHarmony-Stable)."




