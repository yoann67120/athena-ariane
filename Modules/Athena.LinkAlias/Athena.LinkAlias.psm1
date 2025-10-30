# ====================================================================
# ðŸŒ Athena.LinkAlias.psm1 â€“ v1.0 Universal Launcher
# Auteur : Yoann Rousselle / Projet Ariane V4
# Objectif : CrÃ©er la commande universelle Start-AthenaLink
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptPath = Join-Path $RootDir "Scripts\\Start_BridgeSuite.ps1"

function Start-AthenaLink {
    Write-Host "`nðŸš€ Lancement du Pont Cognitif â€“ GPT-5 â†” Athena â†” Cockpit" -ForegroundColor Cyan
    if (Test-Path $ScriptPath) {
        & $ScriptPath
    } else {
        Write-Host "âŒ Script Start_BridgeSuite.ps1 introuvable Ã  $ScriptPath" -ForegroundColor Red
    }
}

Export-ModuleMember -Function Start-AthenaLink
Write-Host "ðŸŒ Module Athena.LinkAlias.psm1 chargÃ© â€“ commande Start-AthenaLink disponible." -ForegroundColor Green


