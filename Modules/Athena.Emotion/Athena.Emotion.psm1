# ====================================================================
# ?? Athena.Emotion.psm1 ï¿½ Moteur d'Humeur Adaptative
# Version : v1.0-AdaptiveMoodEngine
# ====================================================================
# Objectif :
#   - Dï¿½terminer lï¿½ï¿½tat ï¿½motionnel dï¿½Athena selon ses mï¿½triques systï¿½me
#   - Ajuster Cockpit.Signal, Athena.Sound et Athena.Voice
#   - Crï¿½er une cohï¿½rence sensorielle dynamique
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$Summary    = Join-Path $MemoryDir "LearningSummary.json"
$EmotionLog = Join-Path $LogsDir "AthenaEmotion.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

# --------------------------------------------------------------------
# Journal interne
# --------------------------------------------------------------------
function Write-EmotionLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $EmotionLog -Value "[$t] $Msg"
}

# --------------------------------------------------------------------
# Lecture des donnees systeme et apprentissage
# --------------------------------------------------------------------
function Get-SystemEmotionFactors {
    $factors = @{
        CPU       = 0
        RAM       = 0
        Anomalies = 0
        Score     = 100
    }

    try {
        if (Get-Command Get-CockpitData -ErrorAction SilentlyContinue) {
            $d = Get-CockpitData
            $factors.CPU = [double]($d.CPU -replace '[^0-9.]','')
            $factors.RAM = [double]($d.RAM -replace '[^0-9.]','')
        }
    } catch {}

    try {
        if (Test-Path $Summary) {
            $data = Get-Content $Summary -Raw | ConvertFrom-Json
            $factors.Anomalies = [int]$data.anomalies_detected
            $factors.Score     = [double]$data.learning_score
        }
    } catch {}

    return $factors
}

# --------------------------------------------------------------------
# Dï¿½termination de lï¿½humeur en fonction des facteurs
# --------------------------------------------------------------------
function Get-AthenaEmotion {
    $f = Get-SystemEmotionFactors
    $cpu = $f.CPU
    $ram = $f.RAM
    $anom = $f.Anomalies
    $score = $f.Score

    $emotion = "calme"

    if ($cpu -ge 80 -or $ram -ge 85) { $emotion = "irritee" }
    elseif ($anom -ge 5)             { $emotion = "inquiet" }
    elseif ($score -lt 60)           { $emotion = "fatiguee" }
    elseif ($score -gt 95 -and $anom -eq 0 -and $cpu -lt 50) { $emotion = "curieuse" }
    elseif ($cpu -ge 50 -and $cpu -lt 80) { $emotion = "concentree" }
    else { $emotion = "calme" }

    Write-EmotionLog "Etat detecte: $emotion (CPU=$cpu%, RAM=$ram%, Anomalies=$anom, Score=$score)"
    return $emotion
}

# --------------------------------------------------------------------
# Application sensorielle
# --------------------------------------------------------------------
function Invoke-AthenaEmotion {
    Write-Host "`n?? Evaluation de l'humeur d'Athena..." -ForegroundColor Cyan
    $mood = Get-AthenaEmotion

    switch ($mood) {
        "calme" {
            if (Get-Command Set-CockpitMood -ErrorAction SilentlyContinue) {
                Set-CockpitMood -Mood "satisfaite" -State "Sï¿½rï¿½nitï¿½" -Message "Athena est calme et stable."
            }
            if (Get-Command Play-AthenaSound -ErrorAction SilentlyContinue) {
                Play-AthenaSound -Mood "satisfaite" -State "Sï¿½rï¿½nitï¿½"
            }
            if (Get-Command Invoke-AthenaVoice -ErrorAction SilentlyContinue) {
                Invoke-AthenaVoice -Text "Tout est fluide et stable." -Silent
            }
        }
        "concentree" {
            Set-CockpitMood -Mood "attentive" -State "Concentration" -Message "Athena reste concentree."
            Play-AthenaSound -Mood "attentive" -State "Concentration"
            Invoke-AthenaVoice -Text "Je reste concentree sur mes operations." -Silent
        }
        "irritee" {
            Set-CockpitMood -Mood "critique" -State "Vigilance" -Message "Athena subit une charge elevee."
            Play-AthenaSound -Mood "critique" -State "Vigilance"
            Invoke-AthenaVoice -Text "Charge systeme elevee. J'ajuste mes priorites." -Silent
        }
        "inquiet" {
            Set-CockpitMood -Mood "inquiï¿½te" -State "Vigilance" -Message "Athena detecte plusieurs anomalies."
            Play-AthenaSound -Mood "inquiï¿½te" -State "Vigilance"
            Invoke-AthenaVoice -Text "Plusieurs anomalies detectees, je surveille la situation." -Silent
        }
        "fatiguee" {
            Set-CockpitMood -Mood "critique" -State "Sï¿½rï¿½nitï¿½" -Message "Athena semble fatiguee."
            Play-AthenaSound -Mood "critique" -State "Sï¿½rï¿½nitï¿½"
            Invoke-AthenaVoice -Text "Je commence a ressentir une baisse de rendement." -Silent
        }
        "curieuse" {
            Set-CockpitMood -Mood "attentive" -State "Sï¿½rï¿½nitï¿½" -Message "Athena semble curieuse et reactive."
            Play-AthenaSound -Mood "attentive" -State "Sï¿½rï¿½nitï¿½"
            Invoke-AthenaVoice -Text "Je percois de nouvelles donnees interessantes." -Silent
        }
    }

    Write-Host "?? Humeur actuelle : $mood" -ForegroundColor Yellow
    Write-EmotionLog "Humeur appliquee : $mood"
}

Export-ModuleMember -Function Invoke-AthenaEmotion, Get-AthenaEmotion
Write-Host "?? Module Athena.Emotion.psm1 charge (v1.0-AdaptiveMoodEngine)." -ForegroundColor Green
Write-EmotionLog "Module charge avec succes."




