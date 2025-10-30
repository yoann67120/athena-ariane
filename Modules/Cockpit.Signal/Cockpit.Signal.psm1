# ====================================================================
# ðŸ§© Ariane V4 â€“ Cockpit.Signal.psm1 (v2.1-FeedbackFusion-Stable)
# ====================================================================
# Objectif :
#   - GÃ©rer la signalisation visuelle et sensorielle dâ€™Athena
#   - Synchroniser Cockpit.UI, Athena.Sound et Athena.Feedback
#   - Afficher les signaux dâ€™activitÃ© et les humeurs colorÃ©es
#   - Support complet des Ã©tats : SÃ©rÃ©nitÃ© / Concentration / Vigilance
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$SignalLog  = Join-Path $LogsDir "Cockpit.Signal.log"
$DataDir    = Join-Path $RootDir "Data"
$CockpitDir = Join-Path $DataDir "Cockpit"

if (!(Test-Path $LogsDir))   { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (!(Test-Path $CockpitDir)){ New-Item -ItemType Directory -Path $CockpitDir -Force | Out-Null }

function Write-CockpitSignalLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $SignalLog -Value "[$t] $Msg"
}

# ---------------------------------------------------------------
# ðŸš¦ Signal dâ€™activitÃ©
# ---------------------------------------------------------------
function Send-CockpitSignal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet("AthenaThinking","AthenaSpeaking","UserSpeaking","Idle","Error")]
        [string]$Type
    )

    Write-CockpitSignalLog "Signal reÃ§u : $Type"
    switch ($Type) {
        "AthenaThinking" { Write-Host "ðŸ§  [Athena] RÃ©flexion..." -ForegroundColor Yellow }
        "AthenaSpeaking" { Write-Host "ðŸ”´ [Athena] Expression active." -ForegroundColor Red }
        "UserSpeaking"   { Write-Host "ðŸ”µ [Utilisateur] EntrÃ©e vocale." -ForegroundColor Cyan }
        "Idle"           { Write-Host "âš« [SystÃ¨me] Repos visuel." -ForegroundColor DarkGray }
        "Error"          { Write-Host "âŒ [Signal] Erreur dÃ©tectÃ©e." -ForegroundColor Magenta }
    }
    if (Get-Command Update-CockpitDisplay -ErrorAction SilentlyContinue) {
        Update-CockpitDisplay -Signal $Type
    }
}

# ---------------------------------------------------------------
# ðŸŒˆ Humeur et Ã©tat cognitif
# ---------------------------------------------------------------
function Pulse-CockpitColor {
    param([string]$Color="#00AA00",[int]$Duration=3)
    try {
        if ($global:window -and $global:barAthena) {
            $brush = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString($Color))
            $global:window.Dispatcher.Invoke([action]{ 
                $global:barAthena.Fill = $brush
                if ($global:barUser) { $global:barUser.Fill = $brush }
            })
            Start-Sleep -Seconds $Duration
        }
    } catch {}
}

function Set-CockpitMood {
    param(
        [string]$Mood="neutral",
        [string]$State="SÃ©rÃ©nitÃ©",
        [string]$Message=""
    )

    Write-Host "ðŸŽ›ï¸ Cockpit : Ã©tat=$State | humeur=$Mood" -ForegroundColor Cyan
    switch ($State) {
        "SÃ©rÃ©nitÃ©"      { Pulse-CockpitColor -Color "#00AAFF" -Duration 4 }
        "Concentration" { Pulse-CockpitColor -Color "#FFCC00" -Duration 4 }
        "Vigilance"     { Pulse-CockpitColor -Color "#FF0000" -Duration 4 }
        default          { Pulse-CockpitColor -Color "#666666" -Duration 3 }
    }
    if ($Message) { Write-Host "ðŸ“¡ $Message" -ForegroundColor Yellow }
    Write-CockpitSignalLog "Set-CockpitMood mood=$Mood state=$State message=$Message"
}

# ---------------------------------------------------------------
# ðŸ’¨ Respiration visuelle (animation cyclique)
# ---------------------------------------------------------------
function Start-CockpitBreathing {
    param([string]$Color="#0044FF",[int]$Cycles=3)
    Write-Host "ðŸ’¨ Respiration visuelle ($Cycles cycles)..." -ForegroundColor Cyan
    for ($i=0; $i -lt $Cycles; $i++) {
        Pulse-CockpitColor -Color $Color -Duration 2
        Pulse-CockpitColor -Color "#111111" -Duration 2
    }
    Write-CockpitSignalLog "Respiration exÃ©cutÃ©e ($Cycles cycles)"
}

Export-ModuleMember -Function Send-CockpitSignal, Set-CockpitMood, Start-CockpitBreathing
Write-Host "ðŸ§© Cockpit.Signal.psm1 chargÃ© (v2.1-FeedbackFusion-Stable)" -ForegroundColor Magenta
Write-CockpitSignalLog "Module Cockpit.Signal v2.1-FeedbackFusion-Stable chargÃ©"



