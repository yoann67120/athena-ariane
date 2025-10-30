# ====================================================================
# ðŸ§­ Athena.IntentBridge.psm1 â€“ v2.4 Stable (UTF8Clean + Hub Sync)
# Auteur : Yoann Rousselle / Projet Ariane V4
# Description :
#   - InterprÃ©tation et exÃ©cution des intentions GPT locales
#   - Lecture automatique des fichiers InboxGPT (GPT â†’ Athena)
#   - Routage dynamique via Config\IntentMap.json
#   - Journalisation + retour dâ€™Ã©tat au Hub (AthenaLink)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Dossiers & fichiers ===
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ConfigDir  = Join-Path $RootDir "Config"

foreach ($d in @($LogsDir,$MemoryDir,$ConfigDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$LogFile       = Join-Path $LogsDir "IntentBridge.log"
$EventFile     = Join-Path $MemoryDir "Intent_Stats.json"
$IntentMapFile = Join-Path $ConfigDir "IntentMap.json"

# --------------------------------------------------------------------
function Write-IntentLog {
    param([string]$Msg,[string]$Level="INFO")
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$time][$Level] $Msg"
    Write-Host "[$Level] $Msg"
}

# --------------------------------------------------------------------
function Write-IntentEvent {
    param([string]$Intent,[string]$Module,[string]$Result)
    $entry = [ordered]@{
        timestamp = (Get-Date).ToString("s")
        intent    = $Intent
        module    = $Module
        result    = $Result
    }
    $data = @()
    if (Test-Path $EventFile) {
        try { $data = Get-Content -Path $EventFile -Raw | ConvertFrom-Json } catch { $data = @() }
    }
    $data += $entry
    $data | ConvertTo-Json -Depth 4 | Out-File -FilePath $EventFile -Encoding UTF8
}

# --------------------------------------------------------------------
function Validate-Execution {
    try {
        if (Get-Command Invoke-SelfGuardValidation -ErrorAction SilentlyContinue) {
            $ok = Invoke-SelfGuardValidation -Source 'IntentBridge' -FilePath $MyInvocation.MyCommand.Path
            if (-not $ok) {
                Write-IntentLog "â›” Execution blocked by SelfGuard." "WARN"
                return $false
            }
        }
        return $true
    } catch {
        Write-IntentLog "SelfGuard error: $_" "ERROR"
        return $false
    }
}

# --------------------------------------------------------------------
function RouteTo-Module {
    param(
        [string]$Name,
        [string]$Function,
        [hashtable]$Payload,
        [string]$Intent
    )

    try {
        $modulePath = Join-Path (Join-Path $RootDir "Modules") "$Name.psm1"
        if (!(Test-Path $modulePath)) {
            Write-IntentLog "âŒ Module not found: $Name" "ERROR"
            return @{ intent=$Intent; status="error"; message="Module not found: $Name" } | ConvertTo-Json
        }

        Import-Module $modulePath -Force -Global -ErrorAction SilentlyContinue | Out-Null

        if (Get-Command $Function -ErrorAction SilentlyContinue) {
            $rawOutput = ""
            try {
                if ($null -ne $Payload -and $Payload.Count -gt 0) {
                    $rawOutput = & $Function @Payload 2>&1 | Out-String
                } else {
                    $rawOutput = & $Function 2>&1 | Out-String
                }
            } catch {
                $rawOutput = "Error executing $Function in $Name : $($_.Exception.Message)"
            }

            $result = $rawOutput.Trim()
            Write-IntentEvent -Intent $Intent -Module $Name -Result $result
            Send-IntentFeedback -Intent $Intent -Result $result

            Write-Host "âœ… $Name â†’ $Function exÃ©cutÃ© avec succÃ¨s" -ForegroundColor Green
            return @{
                intent  = $Intent
                module  = $Name
                status  = "success"
                output  = $result
                time    = (Get-Date).ToString('s')
            } | ConvertTo-Json -Depth 4
        }
        else {
            return @{ intent=$Intent; status="error"; message="Function $Function not found in $Name" } | ConvertTo-Json
        }
    }
    catch {
        Write-IntentLog "RouteTo-Module ($Name) error: $_" "ERROR"
        return @{ intent=$Intent; status="error"; message="Exception during call to $Name : $($_.Exception.Message)" } | ConvertTo-Json
    }
}

# --------------------------------------------------------------------
function Invoke-AthenaIntent {
    param([string]$Intent,[hashtable]$Payload)

    if (-not (Validate-Execution)) {
        return @{ intent=$Intent; status="denied"; reason="SelfGuard" } | ConvertTo-Json
    }

    Write-IntentLog "Intent received: $Intent"

    $IntentMap = @()
    if (Test-Path $IntentMapFile) {
        try {
            $raw = Get-Content -Path $IntentMapFile -Raw -Encoding UTF8
            $IntentMap = $raw | ConvertFrom-Json
        } catch {
            Write-IntentLog "âš ï¸ Error loading IntentMap.json : $_" "ERROR"
        }
    }

    foreach ($entry in $IntentMap) {
        try {
            $pattern = [Regex]::new($entry.pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $utf8Intent = [Text.Encoding]::UTF8.GetString([Text.Encoding]::Default.GetBytes($Intent))
            if ($pattern.IsMatch($utf8Intent)) {
                Write-Host "ðŸŽ¯ Correspondance trouvÃ©e : $($entry.pattern) â†’ $($entry.module)" -ForegroundColor Green
                return RouteTo-Module -Name $entry.module -Function $entry.function -Payload $Payload -Intent $Intent
            }
        } catch {
            Write-IntentLog "âš ï¸ Regex error for $($entry.pattern) : $_" "WARN"
        }
    }

    Write-IntentLog "No match for intent '$Intent'" "WARN"
    Send-IntentFeedback -Intent $Intent -Result "Intention non reconnue."
    return @{ intent=$Intent; status="unknown"; message="Intention non reconnue" } | ConvertTo-Json
}

# --------------------------------------------------------------------
function Send-IntentFeedback {
    param([string]$Intent,[string]$Result)
    try {
        if (Get-Command Send-HybridMessage -ErrorAction SilentlyContinue) {
            Send-HybridMessage -Source 'IntentBridge' -Intent $Intent -Result $Result
        } elseif (Get-Command Broadcast-Bridge -ErrorAction SilentlyContinue) {
            Broadcast-Bridge -Title 'IntentBridge' -Message $Result -Type 'info'
        } elseif (Get-Command Send-CockpitSignal -ErrorAction SilentlyContinue) {
            Send-CockpitSignal -Type 'AthenaSpeaking'
        } elseif (Get-Command Send-AthenaResult -ErrorAction SilentlyContinue) {
            # Envoi au Hub (AthenaLink)
            Send-AthenaResult -Label "Intent:$Intent" -Content @{ result = $Result }
        }
    } catch {
        Write-IntentLog "Send-IntentFeedback error: $_" "WARN"
    }
}

# --------------------------------------------------------------------
function Initialize-IntentBridge {
    Write-Host "`nðŸ§­ Initialisation d'Athena.IntentBridge v2.4 Stable..." -ForegroundColor Cyan
    Write-IntentLog "Initialization IntentBridge v2.4 Stable."

    if (Test-Path $IntentMapFile) {
        Write-IntentLog "Intent table loaded from $IntentMapFile"
    } else {
        Write-IntentLog "âš ï¸ Missing IntentMap.json, static mode."
    }

    if (Get-Command Register-BridgeHandler -ErrorAction SilentlyContinue) {
        Register-BridgeHandler -Name 'IntentBridge' -Action {
            param($json)
            $req = $json | ConvertFrom-Json
            if ($req) { Invoke-AthenaIntent -Intent $req.intent -Payload $req.payload }
        }
    }

    # DÃ©marre le watcher InboxGPT
    Start-IntentWatcher
    Write-Host "âœ… IntentBridge prÃªt et connectÃ© au Hub." -ForegroundColor Green
}

# --------------------------------------------------------------------
function Start-IntentWatcher {
    $Inbox = Join-Path $RootDir "Server\Memory\InboxGPT"
    if (!(Test-Path $Inbox)) { New-Item -ItemType Directory -Path $Inbox -Force | Out-Null }

    Write-Host "ðŸ‘ï¸ Surveillance du dossier InboxGPT..." -ForegroundColor Cyan
    Write-IntentLog "Watching $Inbox for new intents"

    $watcher = New-Object IO.FileSystemWatcher $Inbox, "*.json"
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true
    $action = {
        $path = $Event.SourceEventArgs.FullPath
        Start-Sleep -Milliseconds 500
        try {
            $json = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($json.intent) {
                Write-Host "ðŸ§  Intent dÃ©tectÃ© : $($json.intent)" -ForegroundColor Yellow
                Invoke-AthenaIntent -Intent $json.intent -Payload $json.payload
            }
        } catch {
            Write-IntentLog "Erreur lecture intent file $path : $_" "ERROR"
        }
    }
    Register-ObjectEvent $watcher Created -Action $action | Out-Null
}

# --------------------------------------------------------------------
function Test-IntentBridge {
    Write-Host "ðŸ§ª Test du Bridge : 'say hello'" -ForegroundColor Cyan
    Invoke-AthenaIntent -Intent "say hello" -Payload @{ target = "world" }
}

# --------------------------------------------------------------------
Export-ModuleMember -Function Invoke-AthenaIntent, Initialize-IntentBridge, Start-IntentWatcher, Test-IntentBridge
Write-Host "ðŸ§­ Module Athena.IntentBridge.psm1 loaded (v2.4 Stable)" -ForegroundColor Green
Write-IntentLog "Module loaded (v2.4 Stable)."


