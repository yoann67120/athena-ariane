# ====================================================================
# ðŸŒ Athena.CommunicationBridge.psm1 â€“ v1.0-AIConnect-Core
# --------------------------------------------------------------------
# Objectif :
#   Ã‰tablir des connexions entre Athena et d'autres IA locales ou
#   distantes. Fournit des fonctions d'envoi/rÃ©ception de messages,
#   de synchronisation mÃ©moire et de surveillance des connexions.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === RÃ©pertoires ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ConfigDir  = Join-Path $RootDir "Config"
$LogFile    = Join-Path $LogsDir "CommunicationBridge.log"
$ConnFile   = Join-Path $MemoryDir "AIConnections.json"
$MsgFile    = Join-Path $MemoryDir "AIExchange.json"

foreach ($p in @($LogsDir,$MemoryDir,$ConfigDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Write-BridgeLog {
    param([string]$Msg,[string]$Level="INFO")
    $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# 1ï¸âƒ£ Connexion Ã  une IA locale (Ollama, LMStudio)
# ====================================================================
function Connect-LocalAI {
    param(
        [ValidateSet("Ollama","LMStudio","TextGenerationWebUI")]
        [string]$Target = "Ollama"
    )
    Write-BridgeLog "Connexion Ã  IA locale : $Target"
    switch ($Target) {
        "Ollama" {
            $uri = "http://127.0.0.1:11434/api/tags"
            try {
                $resp = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 5
                if ($resp.StatusCode -eq 200) {
                    Update-AIConnection -Name "Ollama" -Type "Local" -Status "Connected" -Endpoint $uri
                    Write-Host "âœ… Connexion Ollama Ã©tablie." -ForegroundColor Green
                    return $true
                }
            } catch {
                Write-BridgeLog "âŒ Impossible de contacter Ollama." "ERROR"
                return $false
            }
        }
        "LMStudio" {
            $uri = "http://127.0.0.1:1234/v1/models"
            try {
                $resp = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 5
                if ($resp.StatusCode -eq 200) {
                    Update-AIConnection -Name "LMStudio" -Type "Local" -Status "Connected" -Endpoint $uri
                    Write-Host "âœ… Connexion LMStudio Ã©tablie." -ForegroundColor Green
                    return $true
                }
            } catch {
                Write-BridgeLog "âŒ Impossible de contacter LMStudio." "ERROR"
                return $false
            }
        }
        default { Write-BridgeLog "âš ï¸ IA locale non reconnue : $Target" "WARN" }
    }
}

# ====================================================================
# 2ï¸âƒ£ Connexion Ã  une IA distante (OpenAI, HuggingFace)
# ====================================================================
function Connect-RemoteAI {
    param(
        [ValidateSet("OpenAI","HuggingFace")]
        [string]$Service,
        [string]$ApiKey
    )
    Write-BridgeLog "Connexion Ã  IA distante : $Service"
    if ($Service -eq "OpenAI") {
        $testUri="https://api.openai.com/v1/models"
        try {
            $resp = Invoke-WebRequest -Uri $testUri -Headers @{Authorization="Bearer $ApiKey"} -UseBasicParsing
            if ($resp.StatusCode -eq 200) {
                Update-AIConnection -Name "OpenAI" -Type "Remote" -Status "Connected" -Endpoint $testUri
                Write-Host "âœ… Connexion OpenAI validÃ©e." -ForegroundColor Green
                return $true
            }
        } catch {
            Write-BridgeLog "âŒ ClÃ© OpenAI invalide ou connexion impossible." "ERROR"
            return $false
        }
    }
    elseif ($Service -eq "HuggingFace") {
        $testUri="https://api-inference.huggingface.co/models"
        try {
            $resp = Invoke-WebRequest -Uri $testUri -Headers @{Authorization="Bearer $ApiKey"} -UseBasicParsing
            if ($resp.StatusCode -eq 200) {
                Update-AIConnection -Name "HuggingFace" -Type "Remote" -Status "Connected" -Endpoint $testUri
                Write-Host "âœ… Connexion HuggingFace validÃ©e." -ForegroundColor Green
                return $true
            }
        } catch {
            Write-BridgeLog "âŒ Connexion HuggingFace Ã©chouÃ©e." "ERROR"
            return $false
        }
    }
}

# ====================================================================
# 3ï¸âƒ£ Mise Ã  jour des connexions actives
# ====================================================================
function Update-AIConnection {
    param([string]$Name,[string]$Type,[string]$Status,[string]$Endpoint)
    $list=@()
    if (Test-Path $ConnFile) { try { $list=Get-Content $ConnFile -Raw | ConvertFrom-Json } catch {} }
    $list=$list | Where-Object { $_.Name -ne $Name }
    $list+=[pscustomobject]@{
        Name=$Name; Type=$Type; Status=$Status; Endpoint=$Endpoint; Date=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    $list | ConvertTo-Json -Depth 4 | Out-File $ConnFile -Encoding utf8
}

# ====================================================================
# 4ï¸âƒ£ Envoi de message Ã  une IA connectÃ©e
# ====================================================================
function Send-MessageToAI {
    param([string]$Target,[string]$Message)
    Write-BridgeLog "Envoi message Ã  $Target"
    $entry = $null
    if (Test-Path $ConnFile) {
        $entry = (Get-Content $ConnFile -Raw | ConvertFrom-Json) | Where-Object { $_.Name -eq $Target }
    }
    if ($null -eq $entry) { Write-BridgeLog "âŒ Aucune connexion trouvÃ©e pour $Target" "ERROR"; return }

    switch ($Target) {
        "Ollama" {
            $uri="http://127.0.0.1:11434/api/generate"
            $body=@{ model="mistral"; prompt=$Message } | ConvertTo-Json
            try {
                $resp=Invoke-WebRequest -Uri $uri -Method POST -Body $body -ContentType "application/json"
                $result=$resp.Content | ConvertFrom-Json
                Receive-AIResponse -Source "Ollama" -Data $result
            } catch { Write-BridgeLog "âŒ Ã‰chec envoi Ollama : $_" "ERROR" }
        }
        "LMStudio" {
            $uri="http://127.0.0.1:1234/v1/completions"
            $body=@{ model="gpt-3.5-turbo"; prompt=$Message; max_tokens=100 } | ConvertTo-Json
            try {
                $resp=Invoke-WebRequest -Uri $uri -Method POST -Body $body -ContentType "application/json"
                $result=$resp.Content | ConvertFrom-Json
                Receive-AIResponse -Source "LMStudio" -Data $result
            } catch { Write-BridgeLog "âŒ Ã‰chec envoi LMStudio : $_" "ERROR" }
        }
        default { Write-BridgeLog "âš ï¸ Target non reconnu pour message." "WARN" }
    }
}

# ====================================================================
# 5ï¸âƒ£ RÃ©ception et stockage de rÃ©ponse
# ====================================================================
function Receive-AIResponse {
    param([string]$Source,[object]$Data)
    Write-BridgeLog "RÃ©ponse reÃ§ue depuis $Source"
    $msg=[pscustomobject]@{
        Source=$Source
        Timestamp=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Data=$Data
    }
    $msg | ConvertTo-Json -Depth 6 | Out-File $MsgFile -Encoding utf8
}

# ====================================================================
# 6ï¸âƒ£ Synchronisation mÃ©moire partagÃ©e
# ====================================================================
function Sync-SharedMemory {
    param([string]$Partner)
    Write-BridgeLog "Synchronisation mÃ©moire avec $Partner"
    $sharedFile = Join-Path $MemoryDir "SharedMemory_$Partner.json"
    $allData = @{}
    $memFiles = Get-ChildItem $MemoryDir -Filter "*.json" | Where-Object { $_.Name -notmatch "SharedMemory" }
    foreach ($f in $memFiles) {
        try { $allData[$f.Name] = Get-Content $f.FullName -Raw | ConvertFrom-Json }
        catch { Write-BridgeLog "âš ï¸ Erreur lecture $($f.Name)" "WARN" }
    }
    $allData | ConvertTo-Json -Depth 6 | Out-File $sharedFile -Encoding utf8
    Write-BridgeLog "âœ… MÃ©moire synchronisÃ©e vers $sharedFile"
}

# ====================================================================
# 7ï¸âƒ£ Surveillance des connexions actives
# ====================================================================
function Monitor-AIConnections {
    Write-BridgeLog "VÃ©rification des connexions IA..."
    if (!(Test-Path $ConnFile)) { Write-BridgeLog "Aucune connexion enregistrÃ©e."; return }
    $list = Get-Content $ConnFile -Raw | ConvertFrom-Json
    foreach ($l in $list) {
        Write-Host "[$($l.Type)] $($l.Name) - $($l.Status)" -ForegroundColor Cyan
    }
}

# ====================================================================
# 8ï¸âƒ£ DÃ©connexion propre
# ====================================================================
function Disconnect-AI {
    param([string]$Target)
    Write-BridgeLog "DÃ©connexion IA : $Target"
    if (!(Test-Path $ConnFile)) { return }
    $list=Get-Content $ConnFile -Raw | ConvertFrom-Json
    $list=$list | Where-Object { $_.Name -ne $Target }
    $list | ConvertTo-Json -Depth 4 | Out-File $ConnFile -Encoding utf8
    Write-Host "ðŸ”Œ $Target dÃ©connectÃ©." -ForegroundColor Yellow
}

# ====================================================================
# ðŸ”š Exports publics
# ====================================================================
Export-ModuleMember -Function `
    Connect-LocalAI, `
    Connect-RemoteAI, `
    Send-MessageToAI, `
    Receive-AIResponse, `
    Sync-SharedMemory, `
    Monitor-AIConnections, `
    Disconnect-AI

Write-Host "ðŸŒ Module Athena.CommunicationBridge.psm1 chargÃ© (v1.0-AIConnect-Core)." -ForegroundColor Cyan
Write-BridgeLog "Module CommunicationBridge v1.0 chargÃ©."



