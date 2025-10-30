# ====================================================================
# ðŸ¤ Athena.Connect-GPTArchitect.psm1 â€“ Liaison Ariane â†” GPT Architecte
# Version : v1.1-ConfigLinked (lecture depuis Config\setting)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$ConfigDir = Join-Path $RootDir "Config"
$LogsDir   = Join-Path $RootDir "Logs"

$ConfigFile = Join-Path $ConfigDir "setting"
$LogFile    = Join-Path $LogsDir "GPTArchitect.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-GPTLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

function Get-AthenaConfig {
    try {
        $raw = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        return $raw
    } catch {
        Write-GPTLog "Erreur lecture config: $_" "ERROR"
        return $null
    }
}

function Invoke-GPTArchitect {
    <#
        .SYNOPSIS
        Envoie une instruction au GPT Architecte dÃ©fini dans Config\setting
    #>
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [switch]$Raw
    )

    $cfg = Get-AthenaConfig
    if (-not $cfg) { throw "âš ï¸ Impossible de charger la configuration Ariane." }

    $apiKey  = $cfg.OPENAI_API_KEY
    $apiBase = $cfg.OPENAI_API_BASE
    $model   = $cfg.OPENAI_DEFAULT_MODEL
    $assistantId = $cfg.OPENAI_ASSISTANT_ID

    if (-not $apiKey) { throw "âŒ ClÃ© API OpenAI absente du fichier setting." }

    $uri = "$apiBase/chat/completions"
    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $apiKey"
    }

    $body = @{
        model = $model
        messages = @(
            @{ role = "system"; content = "Tu es Athena Architecte, ingÃ©nieure du systÃ¨me Ariane V4. 
            Fournis uniquement du code PowerShell, des scripts ou des consignes exploitables immÃ©diatement." },
            @{ role = "user"; content = $Prompt }
        )
        temperature = 0.6
    } | ConvertTo-Json -Depth 5

    try {
        $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
        $text = $resp.choices[0].message.content
        Write-GPTLog "RÃ©ponse GPTArchitect: $($text.Substring(0,[Math]::Min($text.Length,200)))..."
        if ($Raw) { return $text } else { return $text.Trim() }
    } catch {
        Write-GPTLog "Erreur API: $_" "ERROR"
        return "âš ï¸ Erreur de communication avec le GPT Architecte."
    }
}

Export-ModuleMember -Function Invoke-GPTArchitect
Write-Host "ðŸ¤ Athena.Connect-GPTArchitect.psm1 chargÃ© (v1.1-ConfigLinked)" -ForegroundColor Cyan




