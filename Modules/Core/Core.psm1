# ====================================================================
# ðŸ§  Core.psm1 â€“ v2.0 Stable (Pont universel IA)
# Liaison cockpit â†” Ariane (LocalModel ou OpenAI)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$ModulesDir = Join-Path $RootDir "Modules"
$LogsDir  = Join-Path $RootDir "Logs"
$LogFile  = Join-Path $LogsDir "Core.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-CoreLog {
    param([string]$Msg,[string]$Level="INFO")
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$time][$Level] $Msg"
}

# ====================================================================
# ðŸ”Œ VÃ©rifie et charge LocalModel si besoin
# ====================================================================
$LocalModelPath = Join-Path $ModulesDir "LocalModel.psm1"
if (Test-Path $LocalModelPath -and -not (Get-Command Invoke-LocalModel -ErrorAction SilentlyContinue)) {
    try {
        Import-Module $LocalModelPath -Force -Global
        Write-CoreLog "âœ… Module LocalModel chargÃ©."
    } catch {
        Write-CoreLog "âŒ Erreur chargement LocalModel : $_" "ERROR"
    }
}

# ====================================================================
# ðŸ§© Fonction : Invoke-LocalCommand (utilisÃ©e par Cockpit)
# ====================================================================
function Invoke-LocalCommand {
    param([Parameter(Mandatory)][string]$Input)

    # Recharge LocalModel Ã  chaque appel si absent
    if (-not (Get-Command Invoke-LocalModel -ErrorAction SilentlyContinue)) {
        $LocalModelPath = Join-Path $ModulesDir "LocalModel.psm1"
        if (Test-Path $LocalModelPath) {
            try {
                Import-Module $LocalModelPath -Force -Global
                Write-CoreLog "ðŸ” Module LocalModel rechargÃ© dynamiquement."
            } catch {
                Write-CoreLog "âŒ Erreur rechargement LocalModel : $_" "ERROR"
                return "Erreur : impossible de charger LocalModel."
            }
        }
    }

    if (Get-Command Invoke-LocalModel -ErrorAction SilentlyContinue) {
        Write-CoreLog "âž¡ï¸ Appel via Invoke-LocalModel."
        try {
            $response = Invoke-LocalModel -Prompt $Input
            Write-CoreLog "âœ… RÃ©ponse IA : $response"
            return $response
        } catch {
            Write-CoreLog "âŒ Erreur exÃ©cution LocalModel : $_" "ERROR"
            return "Erreur : Ã©chec dâ€™exÃ©cution du moteur IA."
        }
    }
    elseif (Get-Command Invoke-OpenAIRequest -ErrorAction SilentlyContinue) {
        Write-CoreLog "âž¡ï¸ Appel via Invoke-OpenAIRequest."
        return Invoke-OpenAIRequest -Prompt $Input
    }
    else {
        Write-CoreLog "âš ï¸ Aucun moteur IA disponible." "WARN"
        return "Aucune interface IA disponible."
    }
}


# ====================================================================
# ðŸ§  Fonction : Invoke-OpenAIRequest (fallback direct OpenAI)
# ====================================================================
function Invoke-OpenAIRequest {
    param([Parameter(Mandatory)][string]$Prompt)

    $Settings = Join-Path $RootDir "Config\settings.json"
    if (!(Test-Path $Settings)) { return "Configuration OpenAI manquante." }

    try {
        $cfg = Get-Content $Settings -Raw | ConvertFrom-Json
        $apiKey  = $cfg.OPENAI_API_KEY
        $apiBase = $cfg.OPENAI_API_BASE
        $model   = $cfg.OPENAI_DEFAULT_MODEL
    } catch {
        return "Erreur lecture settings.json"
    }

    if (-not $apiKey) { return "Aucune clÃ© OpenAI dÃ©tectÃ©e." }

    $uri = "$apiBase/chat/completions"
    $headers = @{ Authorization = "Bearer $apiKey"; "Content-Type"="application/json" }
    $body = @{
        model = $model
        messages = @(@{ role = "user"; content = $Prompt })
        temperature = 0.6
    } | ConvertTo-Json -Depth 5

    try {
        $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Body $body -Method Post -ErrorAction Stop
        $msg = $resp.choices[0].message.content
        Write-CoreLog "RÃ©ponse OpenAI reÃ§ue."
        return $msg
    } catch {
        Write-CoreLog "Erreur API OpenAI : $_" "ERROR"
        return "Erreur de communication avec OpenAI."
    }
}

Export-ModuleMember -Function Invoke-LocalCommand, Invoke-OpenAIRequest
Write-Host "ðŸ§  Core.psm1 v2.0 chargÃ© (pont IA opÃ©rationnel)." -ForegroundColor Cyan
Write-CoreLog "Module Core.psm1 initialisÃ©."


