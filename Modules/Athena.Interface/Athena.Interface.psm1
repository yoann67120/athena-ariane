# ====================================================================
# ðŸŒ Athena.Interface.psm1 â€“ v1.1-EmoPrep
# Connexion Athena â†” Cockpit + gestion Ã©tats Ã©motionnels
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleRoot
$LogsDir     = Join-Path $RootDir "Logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

$LogFile = Join-Path $LogsDir "AthenaInterface.log"

function Write-InterfaceLog {
    param([string]$Msg,[string]$Level="INFO")
    $t=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

function Send-WebSocketMessage {
    param($Socket,[object]$Data)
    try {
        $json = ($Data | ConvertTo-Json -Depth 5 -Compress)
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
        $Socket.Send($buffer)
    } catch {
        Write-InterfaceLog "Erreur envoi WebSocket : $_" "ERROR"
    }
}

# --------------------------------------------------------------------
# âš™ï¸ Serveur principal
# --------------------------------------------------------------------
function Start-AthenaInterface {
    param([int]$Port = 8080)

    Add-Type -AssemblyName System.Net.WebSockets
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("http://*:$Port/")
    $listener.Start()
    Write-Host "âœ… Serveur WebSocket Athena sur port $Port"
    Write-InterfaceLog "Serveur WebSocket dÃ©marrÃ© ($Port)"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        if ($context.Request.IsWebSocketRequest) {
            $wsContext = $context.AcceptWebSocketAsync($null).Result
            $socket = $wsContext.WebSocket
            $global:AthenaTempSocket = @($socket)
            Write-Host "ðŸ¤ Cockpit connectÃ©." -ForegroundColor Yellow
            Write-InterfaceLog "Connexion cockpit acceptÃ©e"

            while ($socket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                Start-Sleep -Milliseconds 800

                $states = @("Safe","Stable","Awakening","Full","Critical")
                $state  = $states | Get-Random
                $colors = @{
                    Safe      = "rouge"
                    Stable    = "bleu"
                    Awakening = "violet"
                    Full      = "blanc"
                    Critical  = "orange"
                }

                $data = @{
                    type     = "status"
                    state    = $state
                    color    = $colors[$state]
                    message  = "Ã‰tat : $state"
                    sound    = switch ($state) {
                        "Safe"      { "beep_down" }
                        "Stable"    { "beep_up" }
                        "Awakening" { "beep_up" }
                        "Full"      { "beep_up" }
                        "Critical"  { "beep_down" }
                    }
                }

                Send-WebSocketMessage -Socket $socket -Data $data
            }
        } else {
            $context.Response.StatusCode = 400
            $context.Response.Close()
        }
    }
}

# --------------------------------------------------------------------
# ðŸ“¡ Envoi manuel
# --------------------------------------------------------------------
function Send-AthenaCockpitMessage {
    param(
        [string]$Message = "Transmission directe",
        [string]$Sound   = "beep_up",
        [string]$State   = "Stable"
    )

    if (-not $global:AthenaTempSocket) {
        Write-Warning "Aucun cockpit connectÃ©."
        return
    }

    $colors = @{
        Safe      = "rouge"
        Stable    = "bleu"
        Awakening = "violet"
        Full      = "blanc"
        Critical  = "orange"
    }

    $packet = @{
        type    = "status"
        message = $Message
        state   = $State
        color   = $colors[$State]
        sound   = $Sound
    }

    $global:AthenaTempSocket | ForEach-Object {
        Send-WebSocketMessage -Socket $_ -Data $packet
    }

    Write-Host "ðŸ“¡ Message '$Message' envoyÃ© au cockpit ($State)" -ForegroundColor Cyan
    Write-InterfaceLog "Message envoyÃ© : $Message | Ã‰tat=$State | Son=$Sound"
}

Export-ModuleMember -Function Start-AthenaInterface, Send-AthenaCockpitMessage
Write-Host "ðŸŒ Module Athena.Interface.psm1 chargÃ© (v1.1-EmoPrep)" -ForegroundColor Cyan
Write-InterfaceLog "Module Interface chargÃ© (v1.1-EmoPrep)."



