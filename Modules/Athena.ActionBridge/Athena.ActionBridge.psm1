# ====================================================================
# ðŸ§© Athena.ActionBridge.psm1 â€“ v1.0 Cognitive Relay
# Pont cognitif entre la voix, GPT et les actions locales
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- RÃ©pertoires
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$LogsDir = Join-Path $RootDir "Logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile = Join-Path $LogsDir "AthenaActionBridge.log"

function Write-BridgeLog {
    param([string]$Msg,[string]$L="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$L] $Msg"
}

# --------------------------------------------------------------------
# ðŸ”¹ Invoke-AthenaAction â€“ cÅ“ur du pont cognitif
# --------------------------------------------------------------------
function Invoke-AthenaAction {
    param([string]$UserInput)

    Write-Host "`nðŸŽ¤ Ordre reÃ§u : $UserInput" -ForegroundColor Yellow
    Write-BridgeLog "Ordre reÃ§u : $UserInput"

    # Ã‰tape 1 : Envoi Ã  GPT pour interprÃ©tation
    $Prompt = @"
Tu es le moteur d'interprÃ©tation d'Athena.
Ta mission : traduire la phrase de l'utilisateur en une commande PowerShell claire.
Si c'est une simple question, rÃ©ponds par du texte.
Si c'est une action, renvoie une ligne PowerShell exÃ©cutable, rien d'autre.
Exemples :
- "redÃ©marre-toi" -> Invoke-AutoPatch
- "analyse les modules" -> Invoke-AthenaSelfVerification
- "ouvre le cockpit" -> Start-CockpitServer
- "quel est ton Ã©tat" -> .\Athena.StatusReport.ps1
EntrÃ©e : "$UserInput"
RÃ©ponse :
"@

    $Result = Invoke-OpenAIRequest -Prompt $Prompt -Model "gpt-4o-mini" -Silent

    if (-not $Result) {
        Write-Warning "âš ï¸ Aucun retour du moteur GPT."
        Write-BridgeLog "Erreur : Pas de rÃ©ponse GPT"
        return
    }

    Write-Host "ðŸ§  InterprÃ©tation : $Result" -ForegroundColor Cyan
    Write-BridgeLog "RÃ©ponse GPT : $Result"

    # Ã‰tape 2 : si GPT renvoie une commande PowerShell, on l'exÃ©cute
    if ($Result -match "Invoke-|Start-|Stop-|\.\\") {
        Write-Host "âš™ï¸ ExÃ©cution locale : $Result" -ForegroundColor Green
        $Output = Invoke-LocalCommand -Command $Result -Silent
        Write-BridgeLog "RÃ©sultat : $Output"
        Write-Host "ðŸ’» RÃ©sultat : $Output" -ForegroundColor Green
    }
    else {
        # Sinon, rÃ©ponse textuelle
        Write-Host "ðŸ’¬ RÃ©ponse : $Result" -ForegroundColor White
    }
}

Export-ModuleMember -Function Invoke-AthenaAction
Write-Host "ðŸ§  Module Athena.ActionBridge.psm1 chargÃ© (pont cognitif actif)." -ForegroundColor Cyan


