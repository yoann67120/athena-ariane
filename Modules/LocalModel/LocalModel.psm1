# ====================================================================
# ðŸ¤– LocalModel.psm1 â€“ Pont Ariane â†” GPT
# Version : v3.6-GPT-Standalone
# Description : communication directe avec GPT, fallback local
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$ConfigDir = Join-Path $RootDir "Config"
$LogsDir   = Join-Path $RootDir "Logs"
$LogFile   = Join-Path $LogsDir "LocalModel.log"
$Settings  = Join-Path $ConfigDir "settings.json"

function Write-LocalLog {
    param([string]$Msg,[string]$Level="INFO")
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level] $Msg"
}

function Invoke-LocalModel {
    param([Parameter(Mandatory)][string]$Prompt)

    if (!(Test-Path $Settings)) {
        Write-Warning "âš ï¸ settings.json manquant."
        return "Erreur : configuration absente."
    }

    try {
        $cfg = Get-Content $Settings -Raw | ConvertFrom-Json
        $apiKey  = $cfg.OPENAI_API_KEY
        $apiBase = $cfg.OPENAI_API_BASE
        $model   = $cfg.OPENAI_DEFAULT_MODEL
    } catch {
        Write-Warning "âš ï¸ Erreur lecture configuration : $_"
        return "Erreur configuration."
    }

    if (-not $apiKey) {
        Write-Host "ðŸ’¡ Mode local sans clÃ© API." -ForegroundColor Yellow
        return "Mode local : pas de clÃ© API."
    }

    $uri = "$apiBase/chat/completions"
    $headers = @{ Authorization = "Bearer $apiKey"; "Content-Type"="application/json" }
    $body = @{
        model=$model
        messages=@(@{role="user";content=$Prompt})
        temperature=0.6
    } | ConvertTo-Json -Depth 5

    try {
        $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Body $body -Method Post -ErrorAction Stop
        $msg  = $resp.choices[0].message.content
        Write-LocalLog "RÃ©ponse GPT reÃ§ue."
        return $msg
    } catch {
        Write-Warning "âš ï¸ Erreur communication GPT : $_"
        Write-LocalLog "Erreur API : $($_.Exception.Message)" "ERROR"
        return "Erreur communication GPT."
    }
}

Export-ModuleMember -Function Invoke-LocalModel
Write-Host "ðŸ¤– LocalModel v3.6-GPT-Standalone chargÃ© (liaison GPT prÃªte)." -ForegroundColor Cyan

















