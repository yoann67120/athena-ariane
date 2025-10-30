# ======================================================================================================
# ðŸ§  Athena Cockpit.SocketServer.psm1
# Version : v5.0 â€“ FullLink Autonomous Communication Core
# Auteur  : Projet Ariane V4
# RÃ´le    : Serveur WebSocket et passerelle de communication entre Athena, le Cockpit Web et le Watchdog
# ======================================================================================================

# ------------------------------------------------------------------------------------------------------
# VARIABLES GLOBALES
# ------------------------------------------------------------------------------------------------------
$Global:CockpitSocket_Clients = @()
$Global:CockpitSocket_Listener = $null
$Global:CockpitSocket_Port = 9091
$Global:CockpitSocket_LogPath = "$env:ARIANE_ROOT\Logs\CockpitSocket.log"

# ------------------------------------------------------------------------------------------------------
function Write-CockpitLog {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "[$timestamp] $Message"
    Add-Content -Path $Global:CockpitSocket_LogPath -Value $entry
    Write-Host "ðŸ›°ï¸ $Message"
}
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
function Start-CockpitSocketServer {
    <#
        .SYNOPSIS
            DÃ©marre le serveur WebSocket interne dâ€™Athena
        .DESCRIPTION
            GÃ¨re la communication temps rÃ©el entre :
            - Cockpit WebUI
            - Watchdog
            - MasterCore
            - Voix / Autres services
    #>

    if ($Global:CockpitSocket_Listener) {
        Write-CockpitLog "Serveur WebSocket dÃ©jÃ  actif sur le port $($Global:CockpitSocket_Port)."
        return
    }

    try {
        Add-Type -AssemblyName System.Net.HttpListener
        $Global:CockpitSocket_Listener = [System.Net.HttpListener]::new()
        $url = "http://*:$($Global:CockpitSocket_Port)/"
        $Global:CockpitSocket_Listener.Prefixes.Add($url)
        $Global:CockpitSocket_Listener.Start()
        Write-CockpitLog "ðŸŒ Serveur WebSocket dÃ©marrÃ© sur $url"

        Start-Job -Name "AthenaSocketServer" -ScriptBlock {
            param($listener)
            Add-Type -AssemblyName System.Net.WebSockets
            while ($listener.IsListening) {
                try {
                    $context = $listener.GetContext()
                    if ($context.Request.IsWebSocketRequest) {
                        $wsContext = $context.AcceptWebSocketAsync($null).Result
                        $socket = $wsContext.WebSocket
                        [void][System.Threading.Interlocked]::Increment([ref]$Global:ClientCounter)
                        $Global:CockpitSocket_Clients += $socket
                        Write-CockpitLog "ðŸ”Œ Client connectÃ© au WebSocket ($($Global:CockpitSocket_Clients.Count) total)"
                        # RÃ©ception continue
                        $buffer = New-Object Byte[] 4096
                        while ($socket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                            $result = $socket.ReceiveAsync((New-Object ArraySegment[byte]($buffer)), [Threading.CancellationToken]::None).Result
                            if ($result.Count -gt 0) {
                                $message = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
                                Write-CockpitLog "ðŸ“© ReÃ§u du Cockpit : $message"
                                # Traitement Ã©ventuel des commandes reÃ§ues
                                if ($message -match "invoke:") {
                                    $cmd = $message.Split(":")[1]
                                    Write-CockpitLog "âš™ï¸ Commande reÃ§ue du Cockpit â†’ $cmd"
                                    Invoke-Expression $cmd
                                }
                            }
                        }
                    } else {
                        $context.Response.StatusCode = 400
                        $context.Response.Close()
                    }
                }
                catch {
                    Write-CockpitLog "âŒ Erreur serveur WebSocket : $($_.Exception.Message)"
                }
            }
        } -ArgumentList $Global:CockpitSocket_Listener | Out-Null
    }
    catch {
        Write-CockpitLog "âŒ Impossible de dÃ©marrer le serveur WebSocket : $($_.Exception.Message)"
    }
}
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
function Send-CockpitMessage {
    param(
        [Parameter(Mandatory)][string]$Message,
        [switch]$SystemLog
    )
    try {
        $data = [System.Text.Encoding]::UTF8.GetBytes($Message)
        # âœ… Compatible .NET 8 / PowerShell 7.5
        $segment = [System.ArraySegment[byte]]::new([byte[]]$data)

        foreach ($client in $Global:CockpitSocket_Clients) {
            if ($client.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                $null = $client.SendAsync(
                    $segment,
                    [System.Net.WebSockets.WebSocketMessageType]::Text,
                    $true,
                    [Threading.CancellationToken]::None
                ).GetAwaiter().GetResult()
            }
        }

        if ($SystemLog) { Write-CockpitLog "ðŸª¶ $Message" }
    }
    catch {
        Write-CockpitLog "âš ï¸ Erreur d'envoi WebSocket : $($_.Exception.Message)"
    }
}


# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
function Stop-CockpitSocketServer {
    try {
        if ($Global:CockpitSocket_Listener) {
            $Global:CockpitSocket_Listener.Stop()
            $Global:CockpitSocket_Listener.Close()
            $Global:CockpitSocket_Listener = $null
            Write-CockpitLog "ðŸ›‘ Serveur WebSocket arrÃªtÃ© proprement."
        }
        foreach ($client in $Global:CockpitSocket_Clients) {
            try { $client.Dispose() } catch {}
        }
        $Global:CockpitSocket_Clients = @()
    }
    catch {
        Write-CockpitLog "âŒ Erreur Ã  l'arrÃªt du serveur WebSocket : $($_.Exception.Message)"
    }
}
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
function Restart-CockpitSocketServer {
    Stop-CockpitSocketServer
    Start-Sleep -Seconds 2
    Start-CockpitSocketServer
}
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
function Get-CockpitClients {
    <#
        .SYNOPSIS
            Liste les clients WebSocket actuellement connectÃ©s.
    #>
    return $Global:CockpitSocket_Clients
}
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
function Invoke-CockpitBroadcast {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("info","success","warning","error","system")][string]$Type = "info"
    )
    $payload = "[$Type] $Title : $Message"
    Send-CockpitMessage -Message $payload -SystemLog
}
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
function Test-CockpitConnection {
    if ($Global:CockpitSocket_Listener -and $Global:CockpitSocket_Listener.IsListening) {
        Write-CockpitLog "âœ… Serveur WebSocket opÃ©rationnel sur le port $($Global:CockpitSocket_Port)"
        return $true
    } else {
        Write-CockpitLog "âŒ Serveur WebSocket inactif."
        return $false
    }
}
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
function Initialize-CockpitSocket {
    <#
        .SYNOPSIS
            Initialise le serveur WebSocket et journalise l'Ã©tat
    #>
    Write-CockpitLog "ðŸš€ Initialisation du serveur Cockpit.SocketServer..."
    Start-CockpitSocketServer
    if (Test-CockpitConnection) {
        Write-CockpitLog "âœ… Initialisation complÃ¨te du SocketServer."
    } else {
        Write-CockpitLog "âš ï¸ Initialisation incomplÃ¨te."
    }
}
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
# ðŸ”® FUTUR : Extensions prÃ©vues (hooks)
# ------------------------------------------------------------------------------------------------------
function Register-CockpitEventHandler {
    <#
        .SYNOPSIS
            Enregistre une fonction PowerShell Ã  exÃ©cuter lorsquâ€™un type de message particulier est reÃ§u du Cockpit.
        .EXAMPLE
            Register-CockpitEventHandler -Event "reload" -Action { Restart-CockpitSocketServer }
    #>
    param(
        [Parameter(Mandatory)][string]$Event,
        [Parameter(Mandatory)][ScriptBlock]$Action
    )
    if (-not $Global:Cockpit_EventHandlers) { $Global:Cockpit_EventHandlers = @{} }
    $Global:Cockpit_EventHandlers[$Event] = $Action
    Write-CockpitLog "ðŸ“¡ Gestionnaire d'Ã©vÃ©nement enregistrÃ© pour : $Event"
}
# ------------------------------------------------------------------------------------------------------

function Invoke-CockpitEvent {
    param([string]$Event)
    if ($Global:Cockpit_EventHandlers.ContainsKey($Event)) {
        & $Global:Cockpit_EventHandlers[$Event]
    } else {
        Write-CockpitLog "âš ï¸ Aucun gestionnaire trouvÃ© pour l'Ã©vÃ©nement $Event"
    }
}
# ------------------------------------------------------------------------------------------------------

Export-ModuleMember -Function * -Alias *
# ======================================================================================================


