# ====================================================================
# ðŸ”— Athena.DirectBridge.psm1 â€“ v1.0-IA-AutonomousLink
# --------------------------------------------------------------------
# RÃ´le :
#   - ReÃ§oit et interprÃ¨te les instructions JSON envoyÃ©es via WebSocket
#   - VÃ©rifie les permissions GPT_Access.json
#   - ExÃ©cute les actions autorisÃ©es (EXEC, PATCH, UPDATE)
#   - Retourne un feedback immÃ©diat vers GPT
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir    = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$ModulesDir = Join-Path $RootDir "Modules"

$AccessFile = Join-Path $MemoryDir "GPT_Access.json"
$LogFile    = Join-Path $LogsDir "DirectBridge.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null }

function Write-BridgeLog {
    param([string]$Msg,[string]$Level='INFO')
    $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ” VÃ©rifie les autorisations
# ====================================================================
function Test-GPTPermission {
    param([string]$Action)
    if (!(Test-Path $AccessFile)) { return $false }
    try {
        $json = Get-Content $AccessFile -Raw | ConvertFrom-Json
        return ($json.$Action -eq $true)
    } catch { return $false }
}

# ====================================================================
# ðŸ§  ExÃ©cution dâ€™instruction JSON
# ====================================================================
function Invoke-DirectCommand {
    param([string]$JsonPayload)

    try {
        $data = $JsonPayload | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-BridgeLog "âŒ JSON invalide reÃ§u."
        return @{ status = "error"; message = "JSON invalide" }
    }

    $intent = $data.intent
    $target = $data.target
    $source = $data.source
    $command = $data.command
    $result = $null

    switch ($intent.ToLower()) {

        "execute" {
            if (!(Test-GPTPermission "allow_execute")) {
                return @{ status="denied"; message="ExÃ©cution non autorisÃ©e." }
            }
            Write-BridgeLog "â–¶ï¸ EXEC: $command"
            try {
                $result = Invoke-Expression $command | Out-String
                return @{ status="ok"; result=$result.Trim() }
            } catch {
                return @{ status="error"; message=$_.Exception.Message }
            }
        }

        "deploy_module" {
            if (!(Test-GPTPermission "allow_update")) {
                return @{ status="denied"; message="Mise Ã  jour non autorisÃ©e." }
            }
            try {
                $file = Join-Path $ModulesDir ([IO.Path]::GetFileName($target))
                Invoke-WebRequest -Uri $source -OutFile $file -UseBasicParsing
                Write-BridgeLog "ðŸ“¦ Module mis Ã  jour : $target"
                Import-Module $file -Force -Global | Out-Null
                return @{ status="ok"; message="Module mis Ã  jour et chargÃ©." }
            } catch {
                return @{ status="error"; message="Ã‰chec mise Ã  jour : $($_.Exception.Message)" }
            }
        }

        "update_system" {
            if (!(Test-GPTPermission "allow_patch")) {
                return @{ status="denied"; message="AutoPatch non autorisÃ©e." }
            }
            try {
                Import-Module (Join-Path $ModulesDir 'Athena.AutoDeploy.psm1') -Force -Global | Out-Null
                Invoke-AthenaAutoDeploy
                return @{ status="ok"; message="AutoDeploy exÃ©cutÃ©." }
            } catch {
                return @{ status="error"; message="Erreur AutoDeploy : $($_.Exception.Message)" }
            }
        }

        default {
            return @{ status="unknown"; message="Intent inconnu : $intent" }
        }
    }
}

Export-ModuleMember -Function Invoke-DirectCommand, Test-GPTPermission
Write-Host "ðŸ”— Module Athena.DirectBridge.psm1 chargÃ© (v1.0-AutonomousLink)." -ForegroundColor Cyan
Write-BridgeLog "Module DirectBridge chargÃ©."
# ====================================================================


