# ====================================================================
# ðŸŒˆ Athena.VisualSync.psm1 â€“ v1.0â€“EmotionSync
# RÃ´le : Synchronisation visuelle (halo + scanner)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WebUI   = Join-Path $RootDir "..\WebUI"

function Update-AthenaVisualEmotion {
    param([string]$State)

    Write-Host "ðŸŒˆ Animation visuelle â†’ $State" -ForegroundColor Cyan
    $jsPath = Join-Path $WebUI "script.js"
    $cssPath = Join-Path $WebUI "style.css"

    if (Test-Path $cssPath) {
        (Get-Content $cssPath) -replace '(?<=--halo-color: ).*;', "--halo-color: $State;" | Set-Content $cssPath
    }

    $marker = Join-Path $WebUI "EmotionIndicator.txt"
    Set-Content -Path $marker -Value "Ã‰motion courante : $State"
}

Export-ModuleMember -Function Update-AthenaVisualEmotion
Write-Host "ðŸŒˆ Athena.VisualSync.psm1 chargÃ© (v1.0â€“EmotionSync)." -ForegroundColor Yellow



