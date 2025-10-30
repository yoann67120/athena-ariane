# ====================================================================
# ðŸ’« Athena.EmotionEngine.psm1
# Version : v1.0â€“EmotionSync
# RÃ´le : Calcul et synchronisation de lâ€™Ã©tat Ã©motionnel global
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$MemoryDir = Join-Path $RootDir "..\Memory"
$LogsDir   = Join-Path $RootDir "..\Logs"

$EmotionFile = Join-Path $MemoryDir "EmotionState.json"
$EmotionLog  = Join-Path $LogsDir "EmotionHistory.log"

# ====================================================================
# ðŸ“˜ Structure de base des Ã©motions
# ====================================================================
$AthenaEmotionMap = @{
    "Safe"          = @{ Color="Red";        Pitch=0.8; Speed=0.9; Volume=0.6; Description="Repli et prudence" }
    "Stable"        = @{ Color="Blue";       Pitch=1.0; Speed=1.0; Volume=0.8; Description="SÃ©rÃ©nitÃ©" }
    "Awakening"     = @{ Color="Purple";     Pitch=1.1; Speed=1.05;Volume=0.9; Description="Ã‰veil, curiositÃ©" }
    "FullAwareness" = @{ Color="White";      Pitch=1.05;Speed=0.95;Volume=1.0; Description="Conscience totale" }
    "Critical"      = @{ Color="Orange";     Pitch=0.95;Speed=1.2; Volume=1.0; Description="Stress / surcharge" }
}

# ====================================================================
# âœï¸ Journalisation
# ====================================================================
function Write-EmotionLog {
    param([string]$Msg)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $EmotionLog -Value "[$timestamp] $Msg"
}

# ====================================================================
# ðŸ§  Fonction principale
# ====================================================================
function Invoke-AthenaEmotion {
    param(
        [Parameter(Mandatory=$true)][string]$State
    )

    if (-not $AthenaEmotionMap.ContainsKey($State)) {
        Write-Warning "âš ï¸ Ã‰motion inconnue : $State"
        return
    }

    $emotion = $AthenaEmotionMap[$State]
    $data = [ordered]@{
        Date       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        State      = $State
        Pitch      = $emotion.Pitch
        Speed      = $emotion.Speed
        Volume     = $emotion.Volume
        Color      = $emotion.Color
        Description= $emotion.Description
    }
# VÃ©rifie que le dossier Memory existe
if (!(Test-Path $MemoryDir)) {
    New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null
    Write-EmotionLog "CrÃ©ation du dossier Memory manquant : $MemoryDir"
}

# VÃ©rifie le chemin complet du fichier
Write-EmotionLog "Chemin de sauvegarde JSON : $EmotionFile"

    # Sauvegarde en JSON
    $data | ConvertTo-Json -Depth 5 | Out-File -FilePath $EmotionFile -Encoding UTF8
    Write-EmotionLog "Changement dâ€™Ã©motion â†’ $State ($($emotion.Description))"
    Write-Host "ðŸ’« Ã‰motion actuelle : $State ($($emotion.Description))" -ForegroundColor Cyan

    # Synchronise les autres modules (voix, audio, visuel)
    if (Get-Command Update-AthenaVoiceEmotion -ErrorAction SilentlyContinue) { Update-AthenaVoiceEmotion $State }
    if (Get-Command Update-AthenaAudioEmotion -ErrorAction SilentlyContinue) { Update-AthenaAudioEmotion $State }
    if (Get-Command Update-AthenaVisualEmotion -ErrorAction SilentlyContinue){ Update-AthenaVisualEmotion $State }
}

Export-ModuleMember -Function Invoke-AthenaEmotion
Write-Host "ðŸ§  Athena.EmotionEngine.psm1 chargÃ© (v1.0â€“EmotionSync)." -ForegroundColor Yellow



