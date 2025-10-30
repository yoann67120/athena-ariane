# ====================================================================
# ðŸŒ Cockpit.Server-Auto.psm1 â€“ Serveur Web auto-dÃ©tectant pour Athena
# Version : v1.2-stable (Auto-Port + UTF8 Fix + Browser Launch)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === DÃ©finition des chemins ===
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$WebDir     = Join-Path $RootDir 'WebUI'
$LogDir     = Join-Path $RootDir 'Logs'
$LogFile    = Join-Path $LogDir 'CockpitServer.log'

if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-CockpitServerLog {
    param([string]$Msg, [string]$Level = 'INFO')
    $time = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $LogFile -Value "[$time][$Level] $Msg"
}

# ====================================================================
# ðŸ” Fonction : Get-FreePort â€“ DÃ©tecte un port libre Ã  partir de 8080
# ====================================================================
function Get-FreePort {
    param([int]$StartPort = 8080)
    for ($p = $StartPort; $p -lt 8100; $p++) {
        if (-not (Test-NetConnection -ComputerName 'localhost' -Port $p -InformationLevel Quiet)) {
            return $p
        }
    }
    throw "Aucun port libre trouvÃ© entre 8080 et 8099."
}

# ====================================================================
# ðŸš€ Fonction : Start-CockpitServer â€“ Lance le serveur Web auto-port
# ====================================================================
function Start-CockpitServer {
    param([int]$PreferredPort = 8080)

    $Port = Get-FreePort -StartPort $PreferredPort

    Write-Host "\nðŸŒ DÃ©marrage du serveur Cockpit sur le port $Port..." -ForegroundColor Cyan
    Write-CockpitServerLog "DÃ©marrage du serveur sur le port $Port"

    Add-Type -AssemblyName System.Net.HttpListener
    $listener = [System.Net.HttpListener]::new()
    $prefix = "http://localhost:$Port/"
    $listener.Prefixes.Add($prefix)

    try {
        $listener.Start()
        Write-Host "âœ… Serveur dÃ©marrÃ© : $prefix" -ForegroundColor Green
        Write-CockpitServerLog "Serveur dÃ©marrÃ© sur $prefix"
        Start-Process $prefix
    } catch {
        Write-Host "âŒ Erreur de dÃ©marrage : $_" -ForegroundColor Red
        Write-CockpitServerLog "Erreur de dÃ©marrage : $_" 'ERROR'
        return
    }

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $response = $context.Response
        $requestPath = $context.Request.Url.LocalPath.TrimStart('/')

        if ([string]::IsNullOrWhiteSpace($requestPath)) { $requestPath = 'index.html' }
        $filePath = Join-Path $WebDir $requestPath

        if (Test-Path $filePath) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentType = Switch -Wildcard ($filePath) {
                    '*.html' { 'text/html; charset=utf-8' }
                    '*.css'  { 'text/css; charset=utf-8' }
                    '*.js'   { 'text/javascript; charset=utf-8' }
                    '*.json' { 'application/json; charset=utf-8' }
                    '*.wav'  { 'audio/wav' }
                    default  { 'text/plain; charset=utf-8' }
                }
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
$response.StatusCode = 200
$response.Headers.Add('Cache-Control','no-cache, no-store, must-revalidate')
                Write-CockpitServerLog "Fichier servi : $filePath"
            } catch {
                Write-CockpitServerLog "Erreur lecture fichier : $_" 'ERROR'
            }
        } else {
            $msg = "404 - Fichier non trouvÃ© ($requestPath)"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
            $response.StatusCode = 404
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            Write-CockpitServerLog $msg 'WARN'
        }

        $response.OutputStream.Close()
    }
}

Export-ModuleMember -Function Start-CockpitServer



