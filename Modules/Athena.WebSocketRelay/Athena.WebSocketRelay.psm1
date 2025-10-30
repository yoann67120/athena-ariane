# ====================================================================
# ðŸ”„ Athena.WebSocketRelay.psm1 â€“ v1.0 Local Relay
# --------------------------------------------------------------------
# RÃ´le :
#   - Relie le serveur WebSocket .exe (port 49392)
#     au pont PowerShell (Start-AthenaAutoBridge)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

function Start-AthenaWebSocketRelay {
    param(
        [string]$ServerUri = "ws://localhost:49392/",
        [int]$BufferSize = 4096
    )

    Write-Host "ðŸ”„ DÃ©marrage du relais WebSocket ($ServerUri)" -ForegroundColor Cyan

    Add-Type -AssemblyName System.Net.WebSockets.Client
    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $uri = [Uri]$ServerUri
    $ws.ConnectAsync($uri,[Threading.CancellationToken]::None).Wait()

    $buffer = New-Object Byte[] $BufferSize
    $segment = [System.ArraySegment[byte]]::new($buffer)

    while ($ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $result = $ws.ReceiveAsync($segment,[Threading.CancellationToken]::None).Result
        if ($result.Count -gt 0) {
            $msg = [Text.Encoding]::UTF8.GetString($buffer,0,$result.Count)
            Write-Host "ðŸ“¡ ReÃ§u du serveur : $msg" -ForegroundColor Yellow

            # --- renvoi vers le pont local ---
            try {
                $relay = [System.Net.WebSockets.ClientWebSocket]::new()
                $relay.ConnectAsync([Uri]"ws://localhost:49392/",[Threading.CancellationToken]::None).Wait()
                $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
                $seg   = [System.ArraySegment[byte]]::new($bytes)
                $relay.SendAsync($seg,[System.Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).Wait()
                $relay.Dispose()
            } catch {
                Write-Host "âš ï¸ Impossible de relayer : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Export-ModuleMember -Function Start-AthenaWebSocketRelay
Write-Host "ðŸ”„ Module Athena.WebSocketRelay.psm1 chargÃ©." -ForegroundColor Cyan
# ====================================================================


