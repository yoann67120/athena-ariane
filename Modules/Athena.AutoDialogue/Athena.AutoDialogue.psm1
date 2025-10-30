# ====================================================================
# ðŸ¤– Athena.AutoDialogue.psm1 â€“ v1.0 CognitiveBridge-Core
# Auteur : Yoann Rousselle / Ariane V4
# RÃ´le : CrÃ©e le pont permanent entre Toi â†” GPT-5 â†” Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Dossiers principaux ===
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$ConfigDir  = Join-Path $RootDir "Config"

$LiveCommand = Join-Path $MemoryDir "LiveCommand.json"
$StatusFile  = Join-Path $MemoryDir "StatusBridge.json"
$LogFile     = Join-Path $LogsDir  "AutoDialogue.log"

foreach ($d in @($MemoryDir,$LogsDir,$ConfigDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# --------------------------------------------------------------------
function Write-AutoDialogueLog {
    param([string]$Msg,[string]$Level="INFO")
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$ts][$Level] $Msg"
}

# --------------------------------------------------------------------
function Sync-AutoDialogueMemory {
    param([string]$State,[string]$LastAction)
    $status = [ordered]@{
        Timestamp  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        State      = $State
        LastAction = $LastAction
    }
    $status | ConvertTo-Json -Depth 3 | Out-File $StatusFile -Encoding UTF8
}

# --------------------------------------------------------------------
function Send-ToGPT {
    param([string]$Prompt)
    try {
        Import-Module (Join-Path $ModuleDir "Athena.HybridLink.psm1") -Force -Global
        $result = Invoke-HybridUnderstanding -Prompt $Prompt
        Write-AutoDialogueLog "Message envoyÃ© Ã  GPT : $Prompt"
        return $result
    } catch {
        Write-AutoDialogueLog "Erreur Send-ToGPT : $_" "ERROR"
        return "Erreur de communication avec GPT-5"
    }
}

# --------------------------------------------------------------------
function Receive-FromGPT {
    param([string]$Response)
    try {
        if ($Response -match "{") {
            $json = $Response | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($json.actionPlan) { return $json.actionPlan }
        }
        return $Response
    } catch {
        Write-AutoDialogueLog "Erreur Receive-FromGPT : $_" "WARN"
        return $Response
    }
}

# --------------------------------------------------------------------
function Execute-AthenaCommand {
    param([string]$Command)
    try {
        Write-Host "âš™ï¸ ExÃ©cution : $Command" -ForegroundColor Cyan
        Write-AutoDialogueLog "ExÃ©cution : $Command"
        Invoke-Expression $Command
        Sync-AutoDialogueMemory -State "Running" -LastAction $Command
    } catch {
        Write-Warning "Erreur pendant lâ€™exÃ©cution : $_"
        Write-AutoDialogueLog "Erreur exÃ©cution : $_" "ERROR"
    }
}

# --------------------------------------------------------------------
function Invoke-DialogueUnderstanding {
    param([string]$InputText)
    if (-not $InputText) { return }
    Write-AutoDialogueLog "EntrÃ©e utilisateur : $InputText"

    $response = Send-ToGPT -Prompt $InputText
    $plan = Receive-FromGPT -Response $response

    if ($plan -is [string]) {
        Write-Host "ðŸ¤– GPT-5 â†’ $plan" -ForegroundColor Magenta
        Write-AutoDialogueLog "RÃ©ponse : $plan"
    } elseif ($plan -is [array]) {
        foreach ($p in $plan) { Execute-AthenaCommand -Command $p }
    }
}

# --------------------------------------------------------------------
function Invoke-AutoDialogueEvolution {
    try {
        Import-Module (Join-Path $ModuleDir "Athena.SelfEvolution.psm1") -Force -Global
        Invoke-AthenaSelfEvolution
        Write-AutoDialogueLog "Cycle Evolution exÃ©cutÃ©."
    } catch { Write-AutoDialogueLog "Erreur Evolution : $_" "WARN" }
}

# --------------------------------------------------------------------
function Export-AutoDialogueSnapshot {
    $snapshot = [ordered]@{
        Date     = (Get-Date).ToString("u")
        LiveCmd  = if (Test-Path $LiveCommand) { Get-Content $LiveCommand -Raw }
        Status   = if (Test-Path $StatusFile)  { Get-Content $StatusFile -Raw }
        Logs     = (Get-Content $LogFile -Tail 20)
    }
    $file = Join-Path $MemoryDir ("Snapshot_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")
    $snapshot | ConvertTo-Json -Depth 5 | Out-File $file -Encoding utf8
    Write-AutoDialogueLog "Snapshot exportÃ© : $file"
}

# --------------------------------------------------------------------
function Start-AthenaAutoDialogue {
    param([int]$IntervalSec = 5)
    Write-Host "`nðŸ’¬ DÃ©marrage du dialogue automatique Athena..." -ForegroundColor Cyan
    Write-AutoDialogueLog "=== DÃ©marrage AutoDialogue ==="
    Sync-AutoDialogueMemory -State "Idle" -LastAction "None"

    while ($true) {
        if (Test-Path $LiveCommand) {
            $cmd = Get-Content $LiveCommand -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($cmd -and $cmd.Command) {
                Write-Host "`nðŸ§  Nouvelle commande dÃ©tectÃ©e : $($cmd.Command)" -ForegroundColor Yellow
                Invoke-DialogueUnderstanding -InputText $cmd.Command
                Remove-Item $LiveCommand -Force
            }
        }
        Start-Sleep -Seconds $IntervalSec
    }
}

# --------------------------------------------------------------------
Export-ModuleMember -Function Start-AthenaAutoDialogue,Invoke-DialogueUnderstanding,Execute-AthenaCommand,Invoke-AutoDialogueEvolution,Export-AutoDialogueSnapshot
Write-Host "ðŸ¤– Module Athena.AutoDialogue.psm1 chargÃ© (v1.0 CognitiveBridge-Core)" -ForegroundColor Cyan
Write-AutoDialogueLog "Module AutoDialogue v1.0 chargÃ©."



