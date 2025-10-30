# ====================================================================
# ðŸ§  Athena.BridgeServer.psm1
# Version : v4.1 â€“ Full WebSocket Handshake + Multi-Client
# Auteur  : Projet Ariane V4 / Athena Core
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Dossiers & logs ---
$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir "Logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile   = Join-Path $LogsDir "BridgeServer.log"

$Global:BridgeServer_Port = 49392
$Global:BridgeServer_Listener = $null
$Global:BridgeServer_Clients  = [System.Collections.Concurrent.ConcurrentBag[System.Net.Sockets.TcpClient]]::new()
$Global:BridgeServer_TokenSource = $null

function Write-BridgeLog {
    param([string]$Msg,[string]$Level="INFO")
    $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
    Write-Host "[$Level] $Msg"
}

# --------------------------------------------------------------------
# ðŸ” Calcul clÃ© handshake
# --------------------------------------------------------------------
function Get-WebSocketAcceptKey {
    param([string]$key)
    $magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($key + $magic)
    $hash  = [System.Security.Cryptography.SHA1]::Create().ComputeHash($bytes)
    return [System.Convert]::ToBase64String($hash)
}

# --------------------------------------------------------------------
# ðŸš€ Start server
# --------------------------------------------------------------------
function Start-AthenaBridgeServer {
    param([int]$Port = $Global:BridgeServer_Port)
    try {
        Write-BridgeLog "ðŸš€ DÃ©marrage BridgeServer (v4.1) sur port $Port..."
        Add-Type -AssemblyName System.Net.Sockets
        $Global:BridgeServer_TokenSource = [System.Threading.CancellationTokenSource]::new()
        $token = $Global:BridgeServer_TokenSource.Token
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any,$Port)
        $Global:BridgeServer_Listener = $listener
        $listener.Start()
        Write-BridgeLog "âœ… Serveur prÃªt sur ws://localhost:$Port"

        Start-Job -Name "BridgeServerLoop" -ScriptBlock {
            param($listener,$logFile,$token)
            while (-not $token.IsCancellationRequested) {
                try {
                    $client = $listener.AcceptTcpClient()
                    if ($client -ne $null) {
                        Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] ðŸ”Œ Client connectÃ©."
                        Start-Job -ScriptBlock {
                            param($tcp,$logFile)
                            try {
                                $stream = $tcp.GetStream()
                                # Lire la requÃªte HTTP initiale
                                $reader = New-Object IO.StreamReader($stream,[Text.Encoding]::ASCII)
                                $req = ""
                                while ($reader.Peek() -ne -1) {
                                    $line = $reader.ReadLine()
                                    if ([string]::IsNullOrWhiteSpace($line)) { break }
                                    $req += "$line`n"
                                }
                                $match=[regex]::Match($req,"Sec-WebSocket-Key: (.*)")
                                if ($match.Success) {
                                    $key=$match.Groups[1].Value.Trim()
                                    $accept=([Convert]::ToBase64String(
                                        [System.Security.Cryptography.SHA1]::Create().ComputeHash(
                                            [Text.Encoding]::UTF8.GetBytes($key+"258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
                                        )
                                    ))
                                    $resp="HTTP/1.1 101 Switching Protocols`r`nUpgrade: websocket`r`nConnection: Upgrade`r`nSec-WebSocket-Accept: $accept`r`n`r`n"
                                    $bytes=[Text.Encoding]::ASCII.GetBytes($resp)
                                    $stream.Write($bytes,0,$bytes.Length)
                                    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] ðŸ¤ Handshake WebSocket rÃ©ussi."

                                    # ============================================================
# ðŸ” Boucle de communication WebSocket persistante (fix)
# ============================================================
$buffer = New-Object byte[] 2048
while ($tcp.Connected -and $stream.CanRead) {
    try {
        $read = $stream.Read($buffer, 0, $buffer.Length)
        if ($read -le 0) { break }

        # DÃ©codage frame WebSocket (supprime masque et entÃªte)
        $fin = ($buffer[0] -band 0x80) -ne 0
        $opcode = $buffer[0] -band 0x0F
        $masked = ($buffer[1] -band 0x80) -ne 0
        $payloadLen = $buffer[1] -band 0x7F
        $offset = 2
        if ($payloadLen -eq 126) {
            $payloadLen = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt16($buffer, 2))
            $offset += 2
        } elseif ($payloadLen -eq 127) {
            $payloadLen = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt64($buffer, 2))
            $offset += 8
        }
        $mask = @(0,0,0,0)
        if ($masked) {
            $mask = $buffer[$offset..($offset+3)]
            $offset += 4
        }

        $decoded = New-Object byte[] $payloadLen
        for ($i = 0; $i -lt $payloadLen; $i++) {
            $decoded[$i] = $buffer[$offset + $i] -bxor $mask[$i % 4]
        }
        $msg = [Text.Encoding]::UTF8.GetString($decoded)

        Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] ðŸ“© ReÃ§u : $msg"

        # Envoie la rÃ©ponse formatÃ©e selon la RFC WebSocket
        $responseText = "ðŸ§  Athena Ack: $msg"
        $payload = [Text.Encoding]::UTF8.GetBytes($responseText)
        $frame = New-Object byte[] ($payload.Length + 2)
        $frame[0] = 0x81  # FIN + opcode texte
        $frame[1] = $payload.Length
        [Array]::Copy($payload, 0, $frame, 2, $payload.Length)
        $stream.Write($frame, 0, $frame.Length)
        $stream.Flush()

    } catch {
        Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] âš ï¸ Erreur rÃ©ception : $_"
        break
    }
}
                                } else {
                                    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] âŒ Handshake WebSocket invalide."
                                }
                            } catch {
                                Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] âš ï¸ Erreur client : $_"
                            } finally {
                                $tcp.Close()
                            }
                        } -ArgumentList $client,$logFile | Out-Null
                    }
                } catch {
                    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] âš ï¸ Erreur listener : $_"
                }
            }
        } -ArgumentList $listener,$LogFile,$token | Out-Null
    } catch {
        Write-BridgeLog "âŒ Erreur dÃ©marrage BridgeServer : $_" "ERROR"
    }
}

function Stop-AthenaBridgeServer {
    try {
        if ($Global:BridgeServer_TokenSource) { $Global:BridgeServer_TokenSource.Cancel(); $Global:BridgeServer_TokenSource.Dispose() }
        if ($Global:BridgeServer_Listener) { $Global:BridgeServer_Listener.Stop(); $Global:BridgeServer_Listener=$null }
        Write-BridgeLog "ðŸ›‘ BridgeServer arrÃªtÃ©."
    } catch { Write-BridgeLog "âŒ Erreur arrÃªt : $_" "ERROR" }
}

function Restart-AthenaBridgeServer { Stop-AthenaBridgeServer; Start-Sleep -Seconds 1; Start-AthenaBridgeServer }

function Test-AthenaBridgeServer {
    $inUse=(Get-NetTCPConnection -State Listen -LocalPort $Global:BridgeServer_Port -ErrorAction SilentlyContinue)
    if ($inUse){Write-BridgeLog "âœ… Port $($Global:BridgeServer_Port) actif.";return $true}else{Write-BridgeLog "âš ï¸ Port inactif.";return $false}
}

Export-ModuleMember -Function Start-AthenaBridgeServer,Stop-AthenaBridgeServer,Restart-AthenaBridgeServer,Test-AthenaBridgeServer
Write-Host "ðŸ§  Module Athena.BridgeServer.psm1 chargÃ© (v4.1 Full WebSocket Handshake + Multi-Client)" -ForegroundColor Cyan
Write-BridgeLog "Module chargÃ© (v4.1 Full WebSocket Handshake + Multi-Client)."


