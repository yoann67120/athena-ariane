# ====================================================================
# ðŸŽ§ Athena.AudioController.psm1 â€“ v0.9-PrepEmotionEngine
# RÃ´le : ContrÃ´leur audio central dâ€™Athena (sons cockpit, volume, TTS)
# Auteur : Yoann Rousselle / Athena Core
# Phase : 30B (prÃ©paration EmotionEngine)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$SoundsDir  = Join-Path $RootDir "WebUI\sounds"
$MemoryDir  = Join-Path $RootDir "Memory"
$AudioStateFile = Join-Path $MemoryDir "AudioSettings.json"

# --- Variables globales ---
$Global:AthenaVolume = 0.5
$Global:AthenaMuted  = $false
$Global:AthenaScannerPlayer = $null

# ====================================================================
# ðŸ”Š Fonction : Write-AudioLog
# ====================================================================
function Write-AudioLog {
    param([string]$Msg,[string]$Level="INFO")
    $t=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $logFile=Join-Path $RootDir "Logs\AthenaAudio.log"
    Add-Content -Path $logFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸŽ›ï¸ Initialize-AthenaAudio
# ====================================================================
function Initialize-AthenaAudio {
    Write-Host "ðŸŽ§ Initialisation du moteur audio Athena..." -ForegroundColor Cyan
    if (!(Test-Path $SoundsDir)) {
        Write-Warning "âŒ Aucun dossier de sons dÃ©tectÃ© : $SoundsDir"
        return
    }

    # Charger volume enregistrÃ©
    if (Test-Path $AudioStateFile) {
        try {
            $state = Get-Content $AudioStateFile -Raw | ConvertFrom-Json
            $Global:AthenaVolume = [double]$state.Volume
            $Global:AthenaMuted  = [bool]$state.Muted
            Write-Host "ðŸ”Š Volume restaurÃ© : $($Global:AthenaVolume*100)% | Mute=$Global:AthenaMuted"
        } catch { Write-Warning "âš ï¸ Fichier AudioSettings.json corrompu." }
    }

    Write-AudioLog "Moteur audio initialisÃ©. Volume=$($Global:AthenaVolume) Mute=$Global:AthenaMuted"
}

# ====================================================================
# â–¶ï¸ Play-AthenaSound
# ====================================================================
function Play-AthenaSound {
    param([Parameter(Mandatory)][string]$Name)
    if ($Global:AthenaMuted) { return }
    $path = Join-Path $SoundsDir "$Name.wav"
    if (!(Test-Path $path)) { Write-Warning "Son introuvable : $Name"; return }
    try {
        $player = New-Object System.Media.SoundPlayer $path
        $player.Play()
        Write-AudioLog "Lecture son : $Name"
    } catch { Write-AudioLog "Erreur lecture son $Name : $_" "ERROR" }
}

# ====================================================================
# ðŸ” Start-AthenaScannerLoop / Stop-AthenaScannerLoop
# ====================================================================
function Start-AthenaScannerLoop {
    if ($Global:AthenaMuted) { return }
    $path = Join-Path $SoundsDir "scanner_loop.wav"
    if (!(Test-Path $path)) { Write-Warning "Son scanner_loop.wav manquant."; return }
    try {
        $player = New-Object System.Media.SoundPlayer $path
        $player.PlayLooping()
        $Global:AthenaScannerPlayer = $player
        Write-Host "ðŸ”´ Scanner audio activÃ©."
        Write-AudioLog "Scanner activÃ©."
    } catch { Write-AudioLog "Erreur scanner_loop : $_" "ERROR" }
}

function Stop-AthenaScannerLoop {
    if ($Global:AthenaScannerPlayer) {
        try {
            $Global:AthenaScannerPlayer.Stop()
            Write-Host "âš« Scanner audio stoppÃ©."
            Write-AudioLog "Scanner stoppÃ©."
        } catch {}
    }
}

# ====================================================================
# ðŸ”ˆ Set-AthenaVolume / Get-AthenaVolume
# ====================================================================
function Set-AthenaVolume {
    param([double]$Level)
    if ($Level -lt 0) { $Level = 0 }
    if ($Level -gt 1) { $Level = 1 }
    $Global:AthenaVolume = $Level
    Save-AthenaAudioState
    Write-Host "ðŸ”Š Volume dÃ©fini Ã  $([int]($Level*100))%"
    Write-AudioLog "Volume=$Level"
}

function Get-AthenaVolume {
    return $Global:AthenaVolume
}

# ====================================================================
# ðŸ”‡ Mute / Unmute
# ====================================================================
function Mute-Athena {
    $Global:AthenaMuted = $true
    Stop-AthenaScannerLoop
    Save-AthenaAudioState
    Write-Host "ðŸ”‡ Sons coupÃ©s."
    Write-AudioLog "Audio mutÃ©."
}

function Unmute-Athena {
    $Global:AthenaMuted = $false
    Start-AthenaScannerLoop
    Save-AthenaAudioState
    Write-Host "ðŸ”Š Sons rÃ©activÃ©s."
    Write-AudioLog "Audio rÃ©activÃ©."
}

# ====================================================================
# ðŸ’¾ Sauvegarde de lâ€™Ã©tat audio
# ====================================================================
function Save-AthenaAudioState {
    $state = @{
        Volume = $Global:AthenaVolume
        Muted  = $Global:AthenaMuted
    }
    $state | ConvertTo-Json -Depth 3 | Out-File $AudioStateFile -Encoding UTF8
}

# ====================================================================
# ðŸ—£ï¸ (PrÃ©-Phase 31) Invoke-AthenaVoice
# ====================================================================
function Invoke-AthenaVoice {
    param([string]$Text="SystÃ¨me prÃªt.")
    try {
        Add-Type -AssemblyName System.Speech
        $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $synth.Volume = [int]($Global:AthenaVolume * 100)
        $synth.Rate   = -1
        $synth.Speak($Text)
        Write-AudioLog "Voix synthÃ¨se : $Text"
    } catch {
        Write-Warning "SynthÃ¨se vocale non disponible sur ce systÃ¨me."
    }
}

# ====================================================================
# âš™ï¸ Fonctions utilitaires avancÃ©es
# ====================================================================
function Test-AthenaAudio {
    Write-Host "ðŸ§ª Test des sons Athena..." -ForegroundColor Yellow
    Play-AthenaSound "beep_up"
    Start-Sleep 1
    Play-AthenaSound "beep_down"
    Start-Sleep 1
    Start-AthenaScannerLoop
    Start-Sleep 3
    Stop-AthenaScannerLoop
    Write-Host "âœ… Test audio terminÃ©."
}

# ====================================================================
# ðŸ”š Export
# ====================================================================
Export-ModuleMember -Function Initialize-AthenaAudio, Play-AthenaSound, Start-AthenaScannerLoop, Stop-AthenaScannerLoop, `
    Set-AthenaVolume, Get-AthenaVolume, Mute-Athena, Unmute-Athena, Save-AthenaAudioState, Invoke-AthenaVoice, Test-AthenaAudio

Write-Host "ðŸŽ§ Module Athena.AudioController.psm1 chargÃ© (v0.9-PrepEmotionEngine)" -ForegroundColor Cyan
Write-AudioLog "Module AudioController chargÃ©."



