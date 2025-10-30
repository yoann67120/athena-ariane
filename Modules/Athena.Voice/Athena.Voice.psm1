# ====================================================================
# ðŸ—£ï¸ Athena.Voice.psm1 â€“ v3.0-Interactive
# Objectif : moteur vocal connectÃ© au cockpit et aux notifications
# Auteur : Ariane V4 / Athena Core
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === Dossiers principaux ===
$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir 'Logs'
$SignalDir = Join-Path $RootDir 'WebUI\Signals'

if (!(Test-Path $LogsDir))  { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (!(Test-Path $SignalDir)) { New-Item -ItemType Directory -Path $SignalDir -Force | Out-Null }

$LogFile = Join-Path $LogsDir 'AthenaVoice.log'

function Write-VoiceLog {
    param([string]$Msg,[string]$Level='INFO')
    $t = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
    Write-Host $Msg -ForegroundColor DarkMagenta
}

# ====================================================================
# ðŸ”Š FONCTION PRINCIPALE
# ====================================================================
function Speak-Athena {
    param(
        [Parameter(Mandatory)][string]$Text,
        [switch]$Silent,
        [switch]$Visual
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        Write-VoiceLog "Texte vide ignorÃ©."
        return
    }

    Write-Host "ðŸ—£ï¸ Athena : $Text" -ForegroundColor Magenta
    Write-VoiceLog "Parole : $Text"

    # --- Halo visuel (signal cockpit) ---
    if ($Visual) {
        try {
            $payload = [pscustomobject]@{
                timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                type      = 'voice'
                message   = $Text
                color     = 'red'
            }
            $SignalFile = Join-Path $SignalDir 'AthenaVoice.json'
            $payload | ConvertTo-Json -Depth 3 | Out-File $SignalFile -Encoding utf8
        } catch {}
    }

    # --- SynthÃ¨se vocale ---
    try {
        Add-Type -AssemblyName System.Speech
        $s = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $s.Volume = 100
        $s.Rate   = 0

        # Recherche d'une voix franÃ§aise
        $voices = $s.GetInstalledVoices() | Where-Object { $_.VoiceInfo.Culture.TwoLetterISOLanguageName -eq 'fr' }
        if ($voices.Count -gt 0) {
            $s.SelectVoice($voices[0].VoiceInfo.Name)
        }

        if ($Silent) {
            $s.SpeakAsync($Text) | Out-Null
        } else {
            $s.Speak($Text)
        }

        Write-VoiceLog "Voix : $Text"
    } catch {
        Write-Warning "âš ï¸ SynthÃ¨se vocale non disponible ($_)."
        Write-VoiceLog "Erreur vocale : $_" 'ERROR'
    }
}

Export-ModuleMember -Function Speak-Athena
Write-Host "ðŸ—£ï¸ Athena.Voice.psm1 chargÃ© (v3.0-Interactive)" -ForegroundColor Yellow
Write-VoiceLog "Module chargÃ© (v3.0-Interactive)"



