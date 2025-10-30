# ====================================================================
# ðŸŒ Cockpit.Server.psm1 â€“ v2.3 Auto-IA (K2000 Web Bridge)
# Auteur : Yoann Rousselle / Projet Ariane V4
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $RootDir
$ModulesDir = Join-Path $RootDir "Modules"
$WebUIDir   = Join-Path $RootDir "WebUI"
# ðŸ”§ Correction Yoann 2025-10-21 : forcer le bon chemin WebUI
if (-not (Test-Path $WebUIDir) -or $WebUIDir -eq "") {
    $WebUIDir = "$env:ARIANE_ROOT\WebUI"
}

$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$SignalFile = Join-Path $WebUIDir "signal.json"
$LogFile    = Join-Path $LogsDir "CockpitServer.log"

foreach ($dir in @($LogsDir,$MemoryDir,$WebUIDir)) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

function Write-CockpitLog {
    param([string]$Msg,[string]$Level="INFO")
    $time=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$time][$Level] $Msg"
}

function Update-Signal {
    param([string]$text,[string]$color="red",[string]$status="INFO")
    $obj = @{
        text   = $text
        time   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        color  = $color
        status = $status
    }
    $obj | ConvertTo-Json | Out-File $SignalFile -Encoding utf8
}

# ====================================================================
# ðŸ§  VÃ©rifie et charge automatiquement le moteur IA
# ====================================================================
function Ensure-IAEngine {
    Write-CockpitLog "ðŸ” VÃ©rification moteur IA..."
    $CorePath = Join-Path $ModulesDir "Core.psm1"
    $LocalModelPath = Join-Path $ModulesDir "LocalModel.psm1"

    if (-not (Get-Command Invoke-LocalModel -ErrorAction SilentlyContinue)) {
        if (Test-Path $LocalModelPath) {
            Import-Module $LocalModelPath -Force -Global
            Write-Host "ðŸ¤– LocalModel importÃ© automatiquement." -ForegroundColor Green
        }
    }

    if (-not (Get-Command Invoke-LocalCommand -ErrorAction SilentlyContinue)) {
        if (Test-Path $CorePath) {
            Import-Module $CorePath -Force -Global
            Write-Host "ðŸ§  Core importÃ© automatiquement." -ForegroundColor Green
        }
    }

    if (Get-Command Invoke-LocalCommand -ErrorAction SilentlyContinue) {
        Write-CockpitLog "âœ… Moteur IA prÃªt (Invoke-LocalCommand dÃ©tectÃ©)."
        return $true
    } else {
        Write-CockpitLog "âš ï¸ Aucun moteur IA disponible." "WARN"
        return $false
    }
}

# ====================================================================
# ðŸš€ Serveur principal
# ====================================================================
function Start-CockpitServer {
    [CmdletBinding()]
    param([int]$Port = 8181)

    Write-Host "`nðŸŒ DÃ©marrage du serveur Cockpit sur le port $Port..." -ForegroundColor Cyan
    Write-CockpitLog "DÃ©marrage du serveur sur le port $Port"

    Ensure-IAEngine | Out-Null

    $listener = [System.Net.HttpListener]::new()
    $prefix = "http://localhost:$Port/"
    $listener.Prefixes.Add($prefix)
    $listener.Start()
    Write-Host "âœ… Serveur actif sur $prefix" -ForegroundColor Green
    Update-Signal "Serveur Cockpit dÃ©marrÃ© sur le port $Port" "green" "READY"

    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            $path = $request.Url.AbsolutePath.ToLower()
            $query = [System.Web.HttpUtility]::ParseQueryString($request.Url.Query)
            Write-CockpitLog "RequÃªte reÃ§ue : $path"

            switch -Regex ($path) {

                # === 1ï¸âƒ£ Dialogue IA ===
                "^/chat" {
                    $msg = $query["message"]
                    Write-Host "ðŸ—£ï¸ Utilisateur : $msg" -ForegroundColor Blue
                    Update-Signal "Utilisateur : $msg" "blue" "USER"

                    $answer = ""
                    try {
                        if (Get-Command Invoke-LocalCommand -ErrorAction SilentlyContinue) {
                            $answer = Invoke-LocalCommand -Input $msg
                        } elseif (Get-Command Invoke-OpenAIRequest -ErrorAction SilentlyContinue) {
                            $answer = Invoke-OpenAIRequest -Prompt $msg
                        } else {
                            $answer = "Aucune interface IA disponible."
                        }
                    } catch {
                        $answer = "Erreur IA : $($_.Exception.Message)"
                    }

                    Write-Host "ðŸ¤– Ariane : $answer" -ForegroundColor Red
                    Update-Signal $answer "red" "AI"

                    $json = @{ reply = $answer } | ConvertTo-Json -Depth 3
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType = "application/json"
                    $response.StatusCode = 200
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                }

                # === 2ï¸âƒ£ Commandes ===
                "^/command" {
                    $btn = $query["btn"]
                    Write-Host "ðŸ•¹ï¸ Commande reÃ§ue : $btn" -ForegroundColor Yellow
                    $result = "Commande $btn exÃ©cutÃ©e."
                    $json = @{ reply = $result } | ConvertTo-Json
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType = "application/json"
                    $response.StatusCode = 200
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                }

                default {
                    $filePath = Join-Path $WebUIDir ($path.TrimStart('/'))
                    if ($path -eq "/" -or [string]::IsNullOrWhiteSpace($path)) {
                        $filePath = Join-Path $WebUIDir "index.html"
                    }
                    if ((Test-Path $filePath) -and -not (Test-Path $filePath -PathType Container)) {
                        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                        switch ($ext) {
                            ".html" { $response.ContentType = "text/html" }
                            ".js"   { $response.ContentType = "application/javascript" }
                            ".css"  { $response.ContentType = "text/css" }
                            ".wav"  { $response.ContentType = "audio/wav" }
                            default { $response.ContentType = "text/plain" }
                        }
                        $bytes = [System.IO.File]::ReadAllBytes($filePath)
                        $response.OutputStream.Write($bytes,0,$bytes.Length)
                    } else {
                        $msg = "404 - Ressource non trouvÃ©e ($path)"
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
                        $response.StatusCode = 404
                        $response.OutputStream.Write($bytes,0,$bytes.Length)
                    }
                    $response.Close()
                }
            }

        } catch {
            Write-CockpitLog "Erreur : $_" "ERROR"
            Update-Signal "Erreur serveur : $_" "red" "ERROR"
        }
    }
}
# ============================================================
# ðŸŒ WebSocket Proxy intÃ©grÃ© â€“ Cockpit.Server.psm1 v2.9
# ============================================================

function Start-CockpitSocket {
    param([int]$Port = 9192)

    try {
        Write-Host "ðŸ›°ï¸ Initialisation du serveur WebSocket Cockpit sur le port $Port..." -ForegroundColor Cyan
        $listener = [System.Net.HttpListener]::new()
       param([int]$Port = 9192)

        $listener.Prefixes.Add($prefix)
        $listener.Start()
        Write-Host "âœ… Serveur WebSocket Cockpit actif sur ws://localhost:$Port" -ForegroundColor Green

        while ($true) {
            $context = $listener.GetContext()

            # Gestion de l'upgrade WebSocket
            if ($context.Request.IsWebSocketRequest) {
                $wsContext = $context.AcceptWebSocketAsync("chat").Result
                $ws = $wsContext.WebSocket
                Write-Host "ðŸ’¬ Client WebSocket connectÃ© au Cockpit." -ForegroundColor Yellow

                $buffer = New-Object byte[] 4096
                while ($ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                    $result = $ws.ReceiveAsync([ArraySegment[byte]]$buffer, [Threading.CancellationToken]::None).Result
                    if ($result.Count -gt 0) {
                        $msg = [Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
                        Write-Host "ðŸ“© Message reÃ§u du Cockpit : $msg" -ForegroundColor Magenta

                        # Redirige vers le BridgeServer dâ€™Athena (port 49392)
                        try {
                            $client = New-Object System.Net.WebSockets.ClientWebSocket
                            $client.ConnectAsync([Uri]"ws://127.0.0.1:49392",[Threading.CancellationToken]::None).Wait()
                            $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
                            $client.SendAsync([ArraySegment[byte]]$bytes, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).Wait()
                            $client.Dispose()
                        } catch {
                            Write-Host "âš ï¸ Impossible de transfÃ©rer le message vers Athena : $_" -ForegroundColor Red
                        }

                        # Envoie un accusÃ© visuel au navigateur
                        $ack = [Text.Encoding]::UTF8.GetBytes("{""from"":""Athena"",""message"":""ReÃ§u : $msg""}")
                        $ws.SendAsync([ArraySegment[byte]]$ack, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).Wait()
                    }
                }
            }
            else {
                # RÃ©ponse HTTP standard (pour fichiers ou tests)
                $response = "Cockpit WebSocket actif sur ws://localhost:$Port"
                $buffer = [Text.Encoding]::UTF8.GetBytes($response)
                $context.Response.ContentLength64 = $buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
            }
        }
    }
    catch {
        Write-Host "âŒ Erreur dans Start-CockpitSocket : $_" -ForegroundColor Red
    }
}

Export-ModuleMember -Function Start-CockpitServer, Update-Signal, Start-CockpitSocket
Write-Host "ðŸŒ Module Cockpit.Server.psm1 chargÃ© (v2.3 Auto-IA)." -ForegroundColor Cyan
Write-CockpitLog "Module Cockpit.Server.psm1 chargÃ© avec Auto-IA."


