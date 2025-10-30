# ====================================================================
# ðŸ§  Athena.ConsoleChat.psm1
# Version : v3.2-CognitiveLink
# Auteur  : Projet Ariane V4 / Athena Core
# Objectif :
#   - Dialogue complet avec GPT-5 via HybridLink
#   - ExÃ©cution directe des intentions locales (IntentBridge)
#   - Support complet du mode EXEC
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Dossiers & fichiers ===
$RootDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $RootDir
$LogsDir   = Join-Path $RootDir "Logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile   = Join-Path $LogsDir "ConsoleChat.log"

$DefaultPort = 49392
$ReconnectDelay = 5

# ====================================================================
# ðŸ§© VÃ©rifie que Core.psm1 est chargÃ© (GPT-5 disponible)
# ====================================================================
if (-not (Get-Command Invoke-OpenAIRequest -ErrorAction SilentlyContinue)) {
    $corePath = "$env:ARIANE_ROOT\Core\Core.psm1"
    if (Test-Path $corePath) {
        Import-Module $corePath -Force -Global
        Write-Host "ðŸ§© Core.psm1 chargÃ© automatiquement (GPT-5 prÃªt)" -ForegroundColor Green
    } else {
        Write-Host "âš ï¸ Core.psm1 introuvable, le lien GPT restera simulÃ©." -ForegroundColor Yellow
    }
}

# ====================================================================
# ðŸ§¾ Logging
# ====================================================================
function Write-ConsoleChatLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
    Write-Host "[$Level] $Msg"
}

# ====================================================================
# ðŸ” DÃ©tection du port WebSocket
# ====================================================================
function Get-AthenaWebSocketPort {
    Write-Host "ðŸ” Recherche du port Athena actif..." -ForegroundColor Yellow
    $fixedPort = 49392
    Write-Host "âœ… Port forcÃ© : $fixedPort (serveur WebSocket natif)" -ForegroundColor Green
    return $fixedPort
}

# ====================================================================
# ðŸŒ Dialogue complet avec Athena via HybridLink + WebSocket
# ====================================================================
function Start-AthenaConsoleChat {
    param(
        [string]$Message = "",
        [switch]$Loop
    )

    Add-Type -AssemblyName System.Net.WebSockets
    $port = Get-AthenaWebSocketPort
    $uri  = "ws://localhost:$port"
    Write-ConsoleChatLog "Connexion Ã  $uri"

    $ws = [System.Net.WebSockets.ClientWebSocket]::new()

    try {
        $ws.ConnectAsync([Uri]$uri,[Threading.CancellationToken]::None).Wait()
        Write-Host "ðŸŒ ConnectÃ© Ã  Athena sur $uri" -ForegroundColor Cyan
    } catch {
        Write-ConsoleChatLog "âŒ Impossible de se connecter Ã  $uri : $($_.Exception.Message)" "ERROR"
        return
    }

    # Initialisation HybridLink
    try {
        if (Get-Command Initialize-HybridLink -ErrorAction SilentlyContinue) {
            Initialize-HybridLink | Out-Null
            Write-ConsoleChatLog "HybridLink initialisÃ© (liaison GPT-5 prÃªte)"
        }
    } catch {
        Write-ConsoleChatLog "âš ï¸ Erreur HybridLink : $_" "WARN"
    }

    do {
        if (-not $Message) {
            Write-Host "`nðŸ’¬ Toi : " -NoNewline -ForegroundColor Blue
            $Message = Read-Host
        }

        if ([string]::IsNullOrWhiteSpace($Message)) { continue }

        # --- Ã‰tape 1 : Envoi WebSocket local ---
        try {
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($Message)
            $segment = [System.ArraySegment[byte]]::new($buffer)
            $ws.SendAsync($segment,[System.Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).Wait()
            Write-ConsoleChatLog "Message envoyÃ© : $Message"
        } catch {
            Write-ConsoleChatLog "âš ï¸ Erreur dâ€™envoi : $_" "WARN"
        }

        # ================================================================
        # ðŸ§© Ã‰tape 2A : DÃ©tection et exÃ©cution dâ€™une intention locale
        # ================================================================
        $executedLocally = $false
        try {
            if (Get-Command Invoke-AthenaTextIntent -ErrorAction SilentlyContinue) {
                Write-ConsoleChatLog "ðŸ§­ Analyse locale de la phrase avant GPT : $Message"
                $localResult = Invoke-AthenaTextIntent -Text $Message
                if ($localResult) {
                    Write-Host "`nðŸ¤– Athena (Action locale) : $localResult`n" -ForegroundColor Yellow
                    Write-ConsoleChatLog "âœ… Action locale exÃ©cutÃ©e : $localResult"
                    $executedLocally = $true
                }
            }
        } catch {
            Write-ConsoleChatLog "âš ï¸ Erreur interprÃ©tation locale : $_" "WARN"
        }

        if (-not $executedLocally) {
            # --- Ã‰tape 2B : Passage via HybridLink / GPT-5 ---
            $reply = ""
            try {
                if (Get-Command Send-HybridMessage -ErrorAction SilentlyContinue) {
                    $reply = Send-HybridMessage -Message $Message
                    Write-ConsoleChatLog "RÃ©ponse GPT-5 reÃ§ue via HybridLink"
                } else {
                    $reply = "HybridLink inactif : message non traitÃ© par GPT-5."
                }
            } catch {
                $reply = "Erreur HybridLink : $($_.Exception.Message)"
                Write-ConsoleChatLog $reply "ERROR"
            }

            # --- Ã‰tape 3 : Affichage standard ---
            Write-Host "`nðŸ¤– Athena : $reply`n" -ForegroundColor Green
        }

        # --- Ã‰tape 4 : VÃ©rification du rÃ©sultat EXEC ---
        $bridgeOutput = "$env:ARIANE_ROOT\Scripts\Bridge_Output.txt"
        if (Test-Path $bridgeOutput) {
            Start-Sleep -Milliseconds 200
            try {
                $execResult = Get-Content $bridgeOutput -Raw
                if ($execResult) {
                    Write-Host "ðŸ“„ RÃ©sultat EXEC local dÃ©tectÃ© :" -ForegroundColor Yellow
                    Write-Host $execResult -ForegroundColor Gray
                    Write-ConsoleChatLog "RÃ©sultat EXEC affichÃ© : $execResult"
                }
            } catch {
                Write-ConsoleChatLog "âš ï¸ Erreur lecture Bridge_Output.txt : $_" "WARN"
            }
            Remove-Item $bridgeOutput -Force -ErrorAction SilentlyContinue
        }

        # --- Ã‰tape 5 : Lecture vocale ---
        if (Get-Command Invoke-AthenaVoice -ErrorAction SilentlyContinue) {
            try { Invoke-AthenaVoice -Text $reply -Silent } catch {}
        }

        $Message = if ($Loop) { "" } else { $null }

    } while ($Loop)

    try { $ws.Dispose() } catch {}
    Write-Host "ðŸ›‘ Session ConsoleChat terminÃ©e." -ForegroundColor DarkGray
}

# ====================================================================
# ðŸš€ Export
# ====================================================================
Export-ModuleMember -Function Start-AthenaConsoleChat, Get-AthenaWebSocketPort
Write-Host "ðŸ§  Module Athena.ConsoleChat.psm1 chargÃ© (v3.2-CognitiveLink)" -ForegroundColor Cyan
Write-ConsoleChatLog "Module chargÃ© (v3.2-CognitiveLink)"


