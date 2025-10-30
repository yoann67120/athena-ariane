# ====================================================================
# ðŸŽ§ Athena.AudioController.Extended.psm1 â€“ v1.0-EmotionSync
# Extension Phase 31 : adaptation du son selon lâ€™Ã©motion courante
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$MemoryDir  = Join-Path $RootDir "..\Memory"
$SoundsDir  = Join-Path $RootDir "..\WebUI\sounds"
$EmotionFile = Join-Path $MemoryDir "EmotionState.json"
$AudioLog    = Join-Path $RootDir "..\Logs\AthenaAudioEmotion.log"

function Write-EmotionAudioLog {
    param([string]$Msg)
    $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $AudioLog -Value "[$t] $Msg"
}

function Update-AthenaAudioEmotion {
    param([string]$State)
    Write-Host "ðŸŽ§ Ajustement audio pour Ã©motion : $State" -ForegroundColor Cyan
    Write-EmotionAudioLog "Mise Ã  jour Audio â†’ $State"

    $map=@{
        "Safe"          = @{File="calm_loop.wav"; Volume=0.5}
        "Stable"        = @{File="harmony_chime.wav"; Volume=0.7}
        "Awakening"     = @{File="vibration_light.wav"; Volume=0.8}
        "FullAwareness" = @{File="clarity_theme.wav"; Volume=1.0}
        "Critical"      = @{File="alert_tone.wav"; Volume=1.0}
    }

    if(!$map.ContainsKey($State)){Write-Warning "Ã‰motion inconnue.";return}
    $cfg=$map[$State]
    $file=Join-Path $SoundsDir $cfg.File
    if(Test-Path $file){
        try{
            $p=New-Object System.Media.SoundPlayer $file
            $p.Play()
            Write-EmotionAudioLog "Lecture : $($cfg.File) (vol=$($cfg.Volume))"
        }catch{Write-EmotionAudioLog "Erreur : $_"}
    }else{
        Write-Host "ðŸ”‡ Fichier $($cfg.File) introuvable."
    }
}

Export-ModuleMember -Function Update-AthenaAudioEmotion
Write-Host "ðŸŽ§ Module Ã©tendu AudioController (v1.0-EmotionSync) chargÃ©." -ForegroundColor Yellow



