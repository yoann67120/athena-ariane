# ====================================================================
# ðŸ§  Athena.ServerCore.psm1
# Version : v3.1-BridgeMode
# Auteur  : Yoann Rousselle / Athena Core
# RÃ´le    : Couche logique interne (Bridge gÃ¨re le rÃ©seau)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$Global:AthenaServer = @{
    Port        = 49392
    Password    = "athena2025"
    IsRunning   = $false
    OnMessage   = $null
}

# --------------------------------------------------------------------
# ðŸ“¡ Simule un serveur logique (pas de port rÃ©seau)
# --------------------------------------------------------------------
function Start-AthenaServer {
    $Global:AthenaServer.IsRunning = $true
    Write-Host "ðŸš€ Athena.ServerCore (BridgeMode) initialisÃ©. Aucun port ouvert." -ForegroundColor Green
}

# --------------------------------------------------------------------
# ðŸ”— Enregistre un handler pour les messages entrants
# --------------------------------------------------------------------
function Register-AthenaMessageHandler {
    param([ScriptBlock]$Handler)
    $Global:AthenaServer.OnMessage = $Handler
    Write-Host "ðŸ”— Handler de message enregistrÃ© (BridgeMode)." -ForegroundColor Cyan
}

# --------------------------------------------------------------------
# ðŸ’¬ Point dâ€™entrÃ©e appelÃ© par le Bridge Node.js
# --------------------------------------------------------------------
function Invoke-AthenaMessage {
    param([string]$Message)

    if (-not $Global:AthenaServer.IsRunning) { Start-AthenaServer }

    Write-Host "ðŸ“¥ Message reÃ§u du Bridge : $Message" -ForegroundColor Yellow

    if ($Global:AthenaServer.OnMessage) {
        & $Global:AthenaServer.OnMessage.Invoke($Message)
    }
    else {
        Write-Host "âš ï¸ Aucun handler enregistrÃ©." -ForegroundColor DarkYellow
    }
}

# --------------------------------------------------------------------
# â¹ï¸ ArrÃªt logique
# --------------------------------------------------------------------
function Stop-AthenaServer {
    $Global:AthenaServer.IsRunning = $false
    Write-Host "ðŸ›‘ Athena.ServerCore arrÃªtÃ© (BridgeMode)." -ForegroundColor Yellow
}

Export-ModuleMember -Function Start-AthenaServer, Stop-AthenaServer, Register-AthenaMessageHandler, Invoke-AthenaMessage


