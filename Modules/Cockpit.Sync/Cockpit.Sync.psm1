# ====================================================================
# ðŸ›°ï¸ Cockpit.Sync.psm1 â€“ Phase 11 : Full Sync Bridge Total
# Auteur : Yoann Rousselle / Athena Core
# Version : v1.0-Complete-Autonomous
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === RÃ©pertoires principaux ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$WebUI      = Join-Path $RootDir "WebUI"
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"

foreach ($p in @($WebUI,$MemoryDir,$LogsDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

$LogFile = Join-Path $LogsDir "CockpitSync.log"

# ====================================================================
# ðŸ“œ Journal interne
# ====================================================================
function Write-CockpitLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸŒ Serveur WebSocket interne
# ====================================================================
Add-Type -AssemblyName System.Net.HttpListener
$Global:CockpitServer = $null
$Global:CockpitClients = [System.Collections.Concurrent.ConcurrentBag[System.Net.WebSockets.WebSocket]]::new()

function Start-CockpitServer {
    param([int]$Port = 9091)
    try {
        if ($Global:CockpitServer) {
            Write-Host "â™»ï¸ Serveur Cockpit dÃ©jÃ  actif."
            return
        }

        $listener = [System.Net.HttpListener]::new()
        $listener.Prefixes.Add("http://+:$Port/")
        $listener.Start()
        Write-Host "ðŸ›°ï¸ Serveur WebSocket Cockpit lancÃ© sur le port $Port" -ForegroundColor Cyan
        Write-CockpitLog "Serveur WebSocket lancÃ© sur le port $Port"
        $Global:CockpitServer = $listener

        # Thread principal dâ€™Ã©coute
        while ($listener.IsListening) {
            $ctx = $listener.GetContext()
            if ($ctx.Request.IsWebSocketRequest) {
                $wsContext = $ctx.AcceptWebSocketAsync($null).Result
                $socket = $wsContext.WebSocket
                $Global:CockpitClients.Add($socket)
                Write-CockpitLog "Client WebSocket connectÃ©."
            } else {
                # Sert les fichiers WebUI en HTTP
                $path = Join-Path $WebUI ($ctx.Request.Url.LocalPath.TrimStart('/'))
                if ((Test-Path $path) -and -not (Test-Path $path -PathType Container)) {
                    $bytes = [System.IO.File]::ReadAllBytes($path)
                    $ctx.Response.ContentType = "text/html"
                    $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
                    $ctx.Response.Close()
                } else {
                    $ctx.Response.StatusCode = 404
                    $ctx.Response.Close()
                }
            }
        }
    }
    catch {
        Write-CockpitLog "âŒ Erreur serveur : $_" "ERROR"
        Stop-CockpitServer
    }
}

function Stop-CockpitServer {
    if ($Global:CockpitServer) {
        $Global:CockpitServer.Stop()
        $Global:CockpitServer = $null
        Write-Host "ðŸ›‘ Serveur Cockpit arrÃªtÃ©."
        Write-CockpitLog "Serveur arrÃªtÃ©."
    }
}

# ====================================================================
# ðŸ” Envoi des mises Ã  jour JSON aux clients connectÃ©s
# ====================================================================
function Send-CockpitUpdate {
    param([string]$Type,[object]$Data)

    $payload = @{
        type = $Type
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        data = $Data
    } | ConvertTo-Json -Depth 5

    foreach ($client in $Global:CockpitClients) {
        try {
            if ($client.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($payload)
                $segment = [System.ArraySegment[byte]]::new($buffer)
                $client.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None) | Out-Null
            }
        } catch {
            Write-CockpitLog "Erreur envoi WS : $_" "WARN"
        }
    }
}

# ====================================================================
# ðŸ§  Lecture des fichiers mÃ©moire
# ====================================================================
function Get-MemoryState {
    $files = @("State.json","EmotionState.json","HarmonyState.json","SystemMetrics.json")
    $result = @{}
    foreach ($f in $files) {
        $path = Join-Path $MemoryDir $f
        if (Test-Path $path) {
            try {
                $result[$f] = Get-Content $path -Raw | ConvertFrom-Json
            } catch { Write-CockpitLog "Erreur lecture $f : $_" "WARN" }
        }
    }
    return $result
}

# ====================================================================
# ðŸ”„ Synchronisation automatique
# ====================================================================
function Invoke-CockpitSync {
    Write-Host "`nðŸ›°ï¸ DÃ©marrage du pont de synchronisation Cockpit..." -ForegroundColor Cyan
    Write-CockpitLog "=== Synchronisation dÃ©marrÃ©e ==="

    Start-Job -Name CockpitSyncLoop -ScriptBlock {
        param($MemoryDir)
        $lastHash = ""
        while ($true) {
            try {
                $jsons = Get-ChildItem $MemoryDir -Filter *.json
                $hash = ($jsons | Get-FileHash -Algorithm SHA256 | Sort-Object Path | ForEach-Object Hash) -join ""
                if ($hash -ne $lastHash) {
                    $data = @{}
                    foreach ($f in $jsons) {
                        try {
                            $data[$f.Name] = Get-Content $f.FullName -Raw | ConvertFrom-Json
                        } catch {}
                    }
                    $payload = $data | ConvertTo-Json -Depth 6
                    $Event = @{
                        type = "memory_update"
                        timestamp = (Get-Date).ToString("HH:mm:ss")
                        data = $data
                    } | ConvertTo-Json -Depth 6
                    $path = Join-Path $MemoryDir "LastSync.json"
                    $Event | Out-File $path -Encoding UTF8
                    $lastHash = $hash
                }
                Start-Sleep -Seconds 3
            } catch { Start-Sleep -Seconds 5 }
        }
    } -ArgumentList $MemoryDir | Out-Null

    Write-Host "âœ… Synchronisation en temps rÃ©el active." -ForegroundColor Green
    Write-CockpitLog "Boucle de sync activÃ©e."
}

# ====================================================================
# ðŸ§ª Test & Auto-RÃ©paration
# ====================================================================
function Test-CockpitSync {
    Write-Host "ðŸ§ª Test du pont Cockpit..." -ForegroundColor Yellow
    if ($Global:CockpitServer) {
        Write-Host "âœ… Serveur WebSocket actif."
    } else {
        Write-Warning "âš ï¸ Serveur inactif, tentative de redÃ©marrage..."
        Start-CockpitServer
    }
    $mem = Get-MemoryState
    if ($mem.Count -eq 0) {
        Write-Warning "âš ï¸ Aucun Ã©tat mÃ©moire dÃ©tectÃ©."
    } else {
        Write-Host "ðŸ§  Ã‰tats dÃ©tectÃ©s : $($mem.Keys -join ', ')"
    }
    Write-Host "âœ… Test terminÃ©."
}

# ====================================================================
# â™»ï¸ Auto-Restauration aprÃ¨s crash
# ====================================================================
Register-EngineEvent PowerShell.Exiting -Action {
    if ($Global:CockpitServer) {
        Write-CockpitLog "Extinction dÃ©tectÃ©e, arrÃªt du serveur."
        Stop-CockpitServer
    }
}

# ====================================================================
# ðŸš€ Initialisation automatique
# ====================================================================
function Initialize-CockpitSync {
    Write-Host "ðŸš€ Initialisation Cockpit.Sync (Phase 11)" -ForegroundColor Cyan
    Start-CockpitServer
    Invoke-CockpitSync
}

Export-ModuleMember -Function Initialize-CockpitSync, Start-CockpitServer, Stop-CockpitServer, `
    Invoke-CockpitSync, Get-MemoryState, Send-CockpitUpdate, Test-CockpitSync

Write-Host "ðŸ›°ï¸ Module Cockpit.Sync.psm1 chargÃ© (v1.0 â€“ Full Sync Bridge Total)" -ForegroundColor Yellow
Write-CockpitLog "Module chargÃ© et opÃ©rationnel."


