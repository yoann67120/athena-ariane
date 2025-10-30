# ====================================================================
# ðŸ§  Athena.BridgeSocket.psm1
# Version : v3.0 â€“ Autonomous Socket Core
# Auteur  : Projet Ariane V4 / Athena Core
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Dossiers & fichiers ---
$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir "Logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile   = Join-Path $LogsDir "BridgeSocket.log"

# --- Variables globales ---
$Global:BridgeSocket_Listener = $null
$Global:BridgeSocket_Clients  = @()
$Global:BridgeSocket_Port     = 9191

# ====================================================================
# ðŸª¶ Journalisation
# ====================================================================
function Write-SocketLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
    Write-Host "[$Level] $Msg"
}

# ====================================================================
# ðŸš€ DÃ©marrage du serveur WebSocket
# ====================================================================
function Start-AthenaBridgeSocket {
    param([int]$Port = 9191)
    Write-SocketLog "ðŸš€ DÃ©marrage du BridgeSocket sur le port $Port..."
    try {
        Add-Type -AssemblyName System.Net.HttpListener
        $Global:BridgeSocket_Listener = [System.Net.HttpListener]::new()
        $url = "http://+:$Port/"
        $Global:BridgeSocket_Listener.Prefixes.Add($url)
        $Global:BridgeSocket_Listener.Start()
        Write-SocketLog "âœ… Serveur WebSocket actif sur $url"

        Start-Job -Name "AthenaBridgeSocketLoop" -ScriptBlock {
            param($listener,$logFile)
            Add-Type -AssemblyName System.Net.WebSockets
            while ($listener.IsListening) {
                try {
                    $context = $listener.GetContext()
                    if ($context.Request.IsWebSocketRequest) {
                        $wsContext = $context.AcceptWebSocketAsync($null).Result
                        $socket = $wsContext.WebSocket
                        Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] Client connectÃ© (BridgeSocket)."
                        while ($socket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                            $buffer = New-Object byte[] 4096
                            $result = $socket.ReceiveAsync(
                                (New-Object ArraySegment[byte]($buffer)),
                                [Threading.CancellationToken]::None
                            ).Result
                            if ($result.Count -gt 0) {
                                $msg = [System.Text.Encoding]::UTF8.GetString($buffer,0,$result.Count)
                                Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] Message reÃ§u : $msg"
                                # Echo
                                $reply = [System.Text.Encoding]::UTF8.GetBytes("BridgeSocket Ack: $msg")
                                $segment = [System.ArraySegment[byte]]::new($reply)
                                $socket.SendAsync($segment,[System.Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).Wait()
                            }
                        }
                    } else {
                        $context.Response.StatusCode = 400
                        $context.Response.Close()
                    }
                } catch {
                    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] âš ï¸ Erreur WebSocket : $_"
                }
            }
        } -ArgumentList $Global:BridgeSocket_Listener,$LogFile | Out-Null
    } catch {
        Write-SocketLog "âŒ Erreur au dÃ©marrage du BridgeSocket : $_" "ERROR"
    }
}

# ====================================================================
# ðŸ›‘ ArrÃªt du serveur
# ====================================================================
function Stop-AthenaBridgeSocket {
    try {
        if ($Global:BridgeSocket_Listener) {
            $Global:BridgeSocket_Listener.Stop()
            $Global:BridgeSocket_Listener.Close()
            $Global:BridgeSocket_Listener = $null
            Write-SocketLog "ðŸ›‘ BridgeSocket arrÃªtÃ© proprement."
        }
    } catch {
        Write-SocketLog "âŒ Erreur Ã  lâ€™arrÃªt du BridgeSocket : $_" "ERROR"
    }
}

# ====================================================================
# ðŸ” RedÃ©marrage
# ====================================================================
function Restart-AthenaBridgeSocket {
    Stop-AthenaBridgeSocket
    Start-Sleep -Seconds 2
    Start-AthenaBridgeSocket
}

# ====================================================================
# ðŸ§ª Test
# ====================================================================
function Test-AthenaBridgeSocket {
    if ($Global:BridgeSocket_Listener -and $Global:BridgeSocket_Listener.IsListening) {
        Write-SocketLog "âœ… BridgeSocket opÃ©rationnel sur port $($Global:BridgeSocket_Port)"
        return $true
    } else {
        Write-SocketLog "âš ï¸ BridgeSocket inactif."
        return $false
    }
}

# ====================================================================
# ðŸ“¤ Export
# ====================================================================
Export-ModuleMember -Function Start-AthenaBridgeSocket, Stop-AthenaBridgeSocket, Restart-AthenaBridgeSocket, Test-AthenaBridgeSocket
Write-Host "ðŸ”Œ Module Athena.BridgeSocket.psm1 chargÃ© (v3.0 Autonomous Socket Core)" -ForegroundColor Cyan
Write-SocketLog "Module chargÃ© (v3.0 Autonomous Socket Core)."


