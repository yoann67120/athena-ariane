# ====================================================================
# ðŸŒ Cockpit.Server-DisplayFix.psm1 â€“ v2.8-ActionBridge
# Objectif : Serveur web interactif complet pour Athena Cockpit
# Auteur : Ariane V4 / Athena Core
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === ParamÃ¨tres principaux ===
$Port     = 9091
$RootDir  = "$env:ARIANE_ROOT"
$WebRoot  = Join-Path $RootDir "WebUI"
$LogsDir  = Join-Path $RootDir "Logs"
$Index    = Join-Path $WebRoot "index.html"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile  = Join-Path $LogsDir "Cockpit.Server.log"
$ActionsLog = Join-Path $LogsDir "CockpitActions.log"

# === Modules liÃ©s ===
$VoiceModule   = Join-Path $RootDir "Modules\Athena.Voice.psm1"
$NotifyModule  = Join-Path $RootDir "Modules\Cockpit.Notify.psm1"
$ActionModule  = Join-Path $RootDir "Modules\Cockpit.Actions.psm1"

# === Fonction de log ===
function Write-CockpitLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
    Write-Host $Msg -ForegroundColor DarkGray
}

# === Fonction dâ€™envoi de notification cockpit ===
function Send-CockpitFeedback {
    param([string]$Message,[string]$Status="info")
    try {
        if (Test-Path $NotifyModule) {
            Import-Module $NotifyModule -Force -Global | Out-Null
            Invoke-CockpitNotify -Message $Message -Status $Status
        }
    } catch {
        Write-CockpitLog "âš ï¸ Feedback error: $($_.Exception.Message)" "WARN"
    }
}

# ====================================================================
# ðŸš€ Serveur principal
# ====================================================================
function Start-CockpitServer {
    Write-Host "`nðŸŒ Initialisation du serveur Athena..." -ForegroundColor Cyan
    Write-CockpitLog "=== Nouveau dÃ©marrage du serveur cockpit ==="

    try {
        $listener = [System.Net.HttpListener]::new()
        $listener.Prefixes.Add("http://*:$Port/")
        $listener.Start()
        Write-Host "âœ… Serveur dÃ©marrÃ© : http://*:$Port/" -ForegroundColor Green
        Write-CockpitLog "Serveur dÃ©marrÃ© sur http://*:$Port/"
        Write-Host "ðŸ“‚ WebUI : $WebRoot" -ForegroundColor DarkGray
    } catch {
        Write-Host "âŒ Erreur de dÃ©marrage serveur : $($_.Exception.Message)" -ForegroundColor Red
        Write-CockpitLog "Erreur de dÃ©marrage : $($_.Exception.Message)" "ERROR"
        return
    }

    Write-Host "ðŸ§  Mode debug actif â€“ Ctrl + C pour arrÃªter" -ForegroundColor Cyan

    while ($listener.IsListening) {
        try {
            $context  = $listener.GetContext()
            $request  = $context.Request
            $response = $context.Response
            $path     = $request.Url.LocalPath
            Write-CockpitLog "RequÃªte reÃ§ue : $path"

            # --- ROUTAGE DES ENDPOINTS ---
            switch -Regex ($path) {

                "^/actions/(.+)$" {
                    $action = $Matches[1].ToLower()
                    Write-CockpitLog "âž¡ï¸ Action cockpit : $action"
                    Add-Content -Path $ActionsLog -Value "[$(Get-Date -Format 'HH:mm:ss')] Action : $action"

                    try {
                        Import-Module $ActionModule -Force -Global | Out-Null
                        $reply = Invoke-CockpitAction -Name $action
                        Send-CockpitFeedback -Message $reply -Status "success"
                    } catch {
                        $reply = "Erreur durant lâ€™action $action : $($_.Exception.Message)"
                        Send-CockpitFeedback -Message $reply -Status "error"
                    }

                    $json = @{ reply = $reply } | ConvertTo-Json
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType = "application/json"
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                    $response.OutputStream.Close()
                    continue
                }

                "^/athena/chat$" {
                    $reader = New-Object System.IO.StreamReader($request.InputStream)
                    $body = $reader.ReadToEnd()
                    $data = ConvertFrom-Json $body -ErrorAction SilentlyContinue
                    $text = $data.text
                    Write-CockpitLog "ðŸ—£ï¸ Chat reÃ§u : $text"

                    $reply = "Je t'Ã©coute depuis le cockpit, mais le moteur Dialogue complet n'est pas encore liÃ© ici."
                    if (Test-Path $VoiceModule) {
                        Import-Module $VoiceModule -Force -Global | Out-Null
                        Speak-Athena -Text $reply
                    }

                    $json = @{ reply = $reply } | ConvertTo-Json
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType = "application/json"
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                    $response.OutputStream.Close()
                    continue
                }

                default {
                    # --- SERVEUR DE FICHIERS ---
                    $file = if ($path -eq "/" -or [string]::IsNullOrEmpty($path)) { $Index } else { Join-Path $WebRoot ($path.TrimStart("/")) }
                    if (!(Test-Path $file)) {
                        $msg = "<h1>404</h1><p>$path</p>"
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
                        $response.StatusCode = 404
                        $response.OutputStream.Write($bytes,0,$bytes.Length)
                        $response.OutputStream.Close()
                        continue
                    }
                    $mime = switch -Regex ($file) {
                        '\.html$' { 'text/html' }
                        '\.css$'  { 'text/css' }
                        '\.js$'   { 'application/javascript' }
                        '\.wav$'  { 'audio/wav' }
                        '\.png$'  { 'image/png' }
                        default   { 'text/plain' }
                    }
                    $bytes = [System.IO.File]::ReadAllBytes($file)
                    $response.ContentType = $mime
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.OutputStream.Close()
                }
            }

        } catch {
            Write-CockpitLog "âš ï¸ Erreur requÃªte : $($_.Exception.Message)" "ERROR"
        }
    }

    $listener.Stop()
    Write-Host "ðŸ›‘ Serveur arrÃªtÃ© proprement." -ForegroundColor DarkGray
    Write-CockpitLog "Serveur arrÃªtÃ© proprement."
}

Export-ModuleMember -Function Start-CockpitServer
Write-Host "ðŸŒ Module Cockpit.Server-DisplayFix.psm1 chargÃ© (v2.8-ActionBridge)" -ForegroundColor Cyan
Write-Host "ðŸ“¦ WebUI : $WebRoot"



