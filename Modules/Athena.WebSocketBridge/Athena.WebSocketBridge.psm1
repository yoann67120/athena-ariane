# ====================================================================
# ðŸ§  Athena.WebSocketBridge.psm1 â€“ v2.3 HybridServer (Compatible PS7)
# Auteur : Projet Ariane V4 / Athena Core
# Objectif :
#   - Serveur WebSocket natif via HttpListener + AcceptWebSocketAsync()
#   - Compatible HybridLink & ConsoleChat
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir  = Split-Path -Parent $RootDir
$LogsDir  = Join-Path $RootDir "Logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile  = Join-Path $LogsDir "WebSocketBridge.log"
$Port     = 49400

# ====================================================================
# ðŸª¶ Log helper
# ====================================================================
function Write-BridgeLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
    Write-Host "[$Level] $Msg"
}

# ====================================================================
# ðŸš€ Serveur WebSocket complet
# ====================================================================
function Start-AthenaWebSocketBridge {
    Write-Host "`nðŸš€ DÃ©marrage du pont WebSocketBridge (ws://localhost:$Port)..." -ForegroundColor Cyan
    Write-BridgeLog "Initialisation du pont sur le port $Port"

    Add-Type -AssemblyName System.Net.HttpListener
    Add-Type -AssemblyName System.Net.WebSockets

    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("http://+:$Port/")
    $listener.Start()
    Write-BridgeLog "âœ… Serveur prÃªt sur ws://localhost:$Port"

    # Boucle principale
    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()

            if ($context.Request.IsWebSocketRequest) {
                # --- Accepter la connexion WebSocket ---
                $wsContext = $context.AcceptWebSocketAsync($null).Result
                $socket = $wsContext.WebSocket
                Write-BridgeLog "ðŸ¤ Client connectÃ© au pont WebSocket."

                # --- Thread de gestion client ---
                Start-Job -ScriptBlock {
                    param($socket)
                    $buffer = New-Object byte[] 4096
                    while ($socket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                        $result = $socket.ReceiveAsync(
                            [System.ArraySegment[byte]]::new($buffer),
                            [Threading.CancellationToken]::None
                        ).Result

                        if ($result.Count -gt 0) {
                            $msg = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
                            Write-Host "ðŸ“¥ ReÃ§u : $msg"

                            # --- Relais vers GPT-5 (HybridLink) ---
                            $reply = "RÃ©ponse simulÃ©e : pont opÃ©rationnel."
                            try {
                                if (Get-Command Send-HybridMessage -ErrorAction SilentlyContinue) {
                                    $reply = Send-HybridMessage -Message $msg
                                }
                            } catch {
                                $reply = "Erreur HybridLink : $($_.Exception.Message)"
                            }

                            # --- Envoi retour ---
                            $resp = [System.Text.Encoding]::UTF8.GetBytes($reply)
                            $segment = [System.ArraySegment[byte]]::new($resp)
                            $socket.SendAsync(
                                $segment,
                                [System.Net.WebSockets.WebSocketMessageType]::Text,
                                $true,
                                [Threading.CancellationToken]::None
                            ).Wait()
                            Write-Host "ðŸ“¤ EnvoyÃ© : $reply"
                        }
                    }
                } -ArgumentList $socket | Out-Null
            } else {
                $context.Response.StatusCode = 400
                $context.Response.Close()
            }
        } catch {
            Write-BridgeLog "âŒ Erreur : $($_.Exception.Message)" "ERROR"
        }
    }
}

# ====================================================================
# ðŸ§¹ Stop
# ====================================================================
function Stop-AthenaWebSocketBridge {
    if ($listener) {
        $listener.Stop()
        Write-BridgeLog "ðŸ›‘ Pont arrÃªtÃ©."
    }
}

Export-ModuleMember -Function Start-AthenaWebSocketBridge, Stop-AthenaWebSocketBridge
Write-Host "ðŸŒ Module Athena.WebSocketBridge.psm1 chargÃ© (v2.3-HybridServer)" -ForegroundColor Cyan
Write-BridgeLog "Module chargÃ© (v2.3-HybridServer)"


