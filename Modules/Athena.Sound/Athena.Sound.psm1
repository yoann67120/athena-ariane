# ==============================================================
# ðŸ”Š Athena.Sound.psm1 â€“ Full Audio-Sensory Synchronisation Engine
# Version : v1.6-FeedbackSync-Stable
# ==============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogDir    = Join-Path $RootDir "Logs"
$DataDir   = Join-Path $RootDir "Data\\Sounds"
$LogFile   = Join-Path $LogDir "AthenaSound.log"

if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-AthenaSoundLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# --------------------------------------------------------------
# â–¶ï¸ Lecture sonore selon humeur/Ã©tat
# --------------------------------------------------------------
function Play-AthenaSound {
    param(
        [Parameter(Mandatory)][string]$Mood,
        [string]$State="SÃ©rÃ©nitÃ©"
    )

    Write-Host "ðŸ”Š Lecture sonore ($Mood / $State)" -ForegroundColor Green
    switch ($State) {
        "SÃ©rÃ©nitÃ©"      { [console]::beep(800,200) }
        "Concentration" { [console]::beep(600,300); [console]::beep(700,300) }
        "Vigilance"     { [console]::beep(400,150); [console]::beep(300,150); [console]::beep(400,150) }
        default          { [console]::beep(500,150) }
    }
    Write-AthenaSoundLog "Sound feedback ($Mood/$State)"
}

Export-ModuleMember -Function Play-AthenaSound
Write-Host "ðŸ”Š Athena.Sound.psm1 chargÃ© (v1.6-FeedbackSync-Stable)" -ForegroundColor Yellow
Write-AthenaSoundLog "Module chargÃ© (v1.6-FeedbackSync-Stable)"




