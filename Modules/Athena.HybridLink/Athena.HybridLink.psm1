# ====================================================================
# ðŸŒ‰ Athena.HybridLink.psm1
# Version : v2.4 â€“ Cognitive Feedback Link + EXEC Full Output Ready
# Auteur  : Projet Ariane V4 / Athena Core
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Dossiers & logs ---
$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir "Logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile   = Join-Path $LogsDir "HybridLink.log"

function Write-HybridLog {
    param([string]$Msg,[string]$Level="INFO")
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$time][$Level] $Msg"
    Write-Host "[$Level] $Msg"
}

# ====================================================================
# ðŸš€ Initialisation du lien hybride
# ====================================================================
function Initialize-HybridLink {
    Write-HybridLog "ðŸš€ Initialisation du lien hybride (port 49392)..."
    $uri = "ws://localhost:49392/"
    $maxAttempts = 5; $delay = 2
    try {
        Add-Type -AssemblyName System.Net.WebSockets
        for ($i=1; $i -le $maxAttempts; $i++) {
            $client = [System.Net.WebSockets.ClientWebSocket]::new()
            try {
                Write-HybridLog "[INFO] Tentative #$i de connexion Ã  $uri"
                $task = $client.ConnectAsync([Uri]$uri,[Threading.CancellationToken]::None)
                $task.Wait(4000)
                if ($client.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                    Write-HybridLog "âœ… Connexion Ã©tablie avec $uri"
                    $msg=[System.Text.Encoding]::UTF8.GetBytes("HybridLink Ready")
                    $seg=[System.ArraySegment[byte]]::new($msg)
                    $client.SendAsync($seg,[System.Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).Wait()
                    break
                } else { Write-HybridLog "âš ï¸ Ã‰chec tentative #$i : Ã©tat $($client.State)" }
            } catch { Write-HybridLog "âš ï¸ Ã‰chec tentative #$i : $($_.Exception.Message)" }
            finally { if ($client.State -ne [System.Net.WebSockets.WebSocketState]::Open){ try{$client.Dispose()}catch{}} }
            Start-Sleep -Seconds $delay
        }
        if ($client.State -ne [System.Net.WebSockets.WebSocketState]::Open){
            Write-HybridLog "âŒ Impossible dâ€™Ã©tablir la connexion aprÃ¨s $maxAttempts tentatives" "ERROR"
        } else { Write-HybridLog "ðŸ§  HybridLink actif (GPT-5 â†” Athena â†” Cockpit)" }
    }
    catch { Write-HybridLog "âŒ Erreur inattendue : $($_.Exception.Message)" "ERROR" }
    finally { Write-HybridLog "SelfHeal terminÃ©." }
}

# ====================================================================
function Start-AthenaHybridLink {
    Write-Host "ðŸ”— DÃ©marrage manuel du lien hybride..." -ForegroundColor Cyan
    Initialize-HybridLink
}

# ====================================================================
# âœ‰ï¸ Transmission entre ConsoleChat et GPT-5
# ====================================================================
function Send-HybridMessage {
    param([string]$Message)

    # --- Interception immÃ©diate EXEC avant GPT ---
   if ($Message -match 'EXEC:') {
    Write-HybridLog "ðŸª„ Interception EXEC immÃ©diate avant envoi GPT"
    try {
        $execResult = Invoke-ExecCommand -IncomingMessage $Message
        if (-not $execResult) {
            Write-HybridLog "âš ï¸ Aucun rÃ©sultat EXEC renvoyÃ© (probablement une erreur ou redirection manquante)"
        } else {
            Write-HybridLog "âœ… RÃ©sultat EXEC renvoyÃ© au chat : $execResult"
        }
        return $execResult
    } catch {
        Write-HybridLog "âŒ Erreur lors de lâ€™invocation EXEC : $($_.Exception.Message)" "ERROR"
        return "Erreur HybridLink EXEC : $($_.Exception.Message)"
    }
}

    Write-HybridLog "ðŸ§  Envoi du message Ã  GPT-5 : $Message"
    try {
        if (Get-Command Invoke-OpenAIRequest -ErrorAction SilentlyContinue) {
            $params=@{Prompt=$Message;Model="gpt-5";Temperature=0.7}
            $reply=Invoke-OpenAIRequest @params
            Write-HybridLog "âœ… RÃ©ponse GPT-5 : $reply"
            return $reply
        } else {
            Write-HybridLog "âš ï¸ Fonction Invoke-OpenAIRequest introuvable, simulation activÃ©e."
            return "RÃ©ponse simulÃ©e de GPT-5 pour : $Message"
        }
    }
    catch {
        Write-HybridLog "âŒ Erreur Send-HybridMessage : $($_.Exception.Message)" "ERROR"
        return "Erreur HybridLink : $($_.Exception.Message)"
    }
}

# ====================================================================
# âš™ï¸ EXEC Mode â€“ Capture complÃ¨te PowerShell (sortie nettoyÃ©e)
# ====================================================================
function Invoke-ExecCommand {
    param([string]$IncomingMessage)

    if ($IncomingMessage -match '^EXEC:') {
        $cmd = $IncomingMessage -replace '^EXEC:\s*', ''
        try {
            Write-HybridLog "âš™ï¸ ExÃ©cution locale (runspace + capture propre) : $cmd"

            $rs = [runspacefactory]::CreateRunspace()
            $rs.Open()
            $ps = [PowerShell]::Create()
            $ps.Runspace = $rs

            # --- Transcript temporaire ---
            $tempFile = [System.IO.Path]::GetTempFileName()
            Start-Transcript -Path $tempFile -Append -ErrorAction SilentlyContinue | Out-Null

            $ps.AddScript($cmd) | Out-Null
            $null = $ps.Invoke()

            Stop-Transcript | Out-Null
            $rs.Close(); $ps.Dispose()

            # --- Lecture + nettoyage du transcript ---
            $raw = Get-Content -Path $tempFile -Raw -ErrorAction SilentlyContinue
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

            $lines = $raw -split "`r?`n"
          $filtered = $lines | Where-Object {
    ($_ -notmatch "PowerShell transcript (start|end)") -and
    ($_ -notmatch "Start time:") -and
    ($_ -notmatch "End time:") -and
    ($_ -notmatch "RunAs User:") -and
    ($_ -notmatch "Username:") -and
    ($_ -notmatch "Machine:") -and
    ($_ -notmatch "PSVersion:") -and
    ($_ -notmatch "PSEdition:") -and
    ($_ -notmatch "Configuration Name:") -and
    ($_ -notmatch "Host Application:") -and
    ($_ -notmatch "Process ID:") -and
    ($_ -notmatch "Platform:") -and
    ($_ -notmatch "OS:") -and
    ($_ -notmatch "PSCompatibleVersions:") -and
    ($_ -notmatch "SerializationVersion:") -and
    ($_ -notmatch "GitCommitId:") -and
    ($_ -notmatch "WSManStackVersion:") -and
    ($_ -notmatch "PSRemotingProtocolVersion:") -and
    ($_ -notmatch "\*{10,}")
}

            $result = ($filtered -join "`n").Trim()
            if (-not $result) { $result = "(aucune sortie retournÃ©e)" }

            Write-Host $result -ForegroundColor Gray
            Write-Host "âœ… Commande EXEC exÃ©cutÃ©e avec succÃ¨s." -ForegroundColor Green
            Write-HybridLog "âœ… Commande EXEC exÃ©cutÃ©e avec succÃ¨s : $cmd"

            # --- Sauvegarde propre ---
            $bridgeFile = "$env:ARIANE_ROOT\Scripts\Bridge_Output.txt"
            $reply = "âœ… EXEC â†’ $cmd`n$result"
            Set-Content -Path $bridgeFile -Value $reply -Encoding UTF8 -Force
            Write-HybridLog "ðŸ“¤ RÃ©sultat EXEC enregistrÃ© dans $bridgeFile"

            return $reply
        }
        catch {
            $err = $_.Exception.Message
            Write-Host "âŒ Erreur EXEC : $err" -ForegroundColor Red
            Write-HybridLog "âŒ Erreur EXEC : $err" "ERROR"
            $bridgeFile = "$env:ARIANE_ROOT\Scripts\Bridge_Output.txt"
            $reply = "âŒ Erreur lors de lâ€™exÃ©cution de la commande EXEC : $err"
            Set-Content -Path $bridgeFile -Value $reply -Encoding UTF8 -Force
            return $reply
        }
    }
}

# ====================================================================
Write-Host "ðŸš€ Initialisation complÃ¨te d'Athena.HybridLink v2.4 (EXEC Full Output Ready)" -ForegroundColor Green
Write-HybridLog "Module chargÃ© (v2.4 Cognitive Feedback Link + EXEC Full Output Ready)."

Export-ModuleMember -Function Initialize-HybridLink,Start-AthenaHybridLink,Send-HybridMessage,Invoke-ExecCommand


