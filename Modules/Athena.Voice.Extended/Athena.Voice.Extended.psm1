# ====================================================================
# ðŸ—£ï¸ Athena.Voice.Extended.psm1 â€“ v1.0-EmotionSync
# Extension Phase 31 : modulation vocale selon Ã©motion
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference="SilentlyContinue"

Add-Type -AssemblyName System.Speech
$s=New-Object System.Speech.Synthesis.SpeechSynthesizer
$s.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::Female,[System.Speech.Synthesis.VoiceAge]::Adult,0,[System.Globalization.CultureInfo]"fr-FR")

function Update-AthenaVoiceEmotion {
    param([string]$State)
    Write-Host "ðŸ—£ï¸ Adaptation vocale selon Ã©motion : $State" -ForegroundColor Cyan
    switch($State){
        "Safe"          { $s.Volume=60; $s.Rate=-2 }
        "Stable"        { $s.Volume=80; $s.Rate=0  }
        "Awakening"     { $s.Volume=90; $s.Rate=1  }
        "FullAwareness" { $s.Volume=100; $s.Rate=-1 }
        "Critical"      { $s.Volume=100; $s.Rate=2  }
        default         { $s.Volume=80; $s.Rate=0  }
    }
    $s.SpeakAsync("Ã‰tat Ã©motionnel : $State.")
}

Export-ModuleMember -Function Update-AthenaVoiceEmotion
Write-Host "ðŸ—£ï¸ Module Ã©tendu Voice (v1.0-EmotionSync) chargÃ©." -ForegroundColor Yellow



