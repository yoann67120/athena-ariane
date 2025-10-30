# ====================================================================
# ðŸ§  Athena.IntentTranslator.psm1
# Version : v3.0 â€“ Universal Cognitive Parser
# Auteur  : Yoann Rousselle / Projet Ariane V4
# RÃ´le :
#   - Traduction du texte naturel en intentions exploitables
#   - Apprentissage automatique des nouvelles phrases
#   - Mise Ã  jour dynamique de Config\IntentMap.json
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Dossiers principaux ===
$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$MemoryDir = Join-Path $RootDir "Memory"
$ConfigDir = Join-Path $RootDir "Config"
$LogsDir   = Join-Path $RootDir "Logs"

foreach ($d in @($MemoryDir, $ConfigDir, $LogsDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$IntentFile  = Join-Path $MemoryDir "Intent_Learning.json"
$IntentMap   = Join-Path $ConfigDir "IntentMap.json"
$IntentLog   = Join-Path $LogsDir "IntentTranslator.log"

# ====================================================================
# ðŸ§¾ Logging
# ====================================================================
function Write-IntentTranslatorLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $IntentLog -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ§© Apprentissage
# ====================================================================
function Learn-NewIntent {
    param([string]$Text,[string]$Intent)

    if (-not $Text -or -not $Intent) { return }

    $entry = @{
        timestamp = (Get-Date).ToString("s")
        text      = $Text
        intent    = $Intent
    }

    $data = @()  # <== on force ici un tableau
    if (Test-Path $IntentFile) {
        try {
            $jsonData = Get-Content $IntentFile -Raw | ConvertFrom-Json
            if ($jsonData -is [System.Collections.IEnumerable]) {
                $data = @($jsonData)
            } else {
                $data = @($jsonData)
            }
        } catch {
            $data = @()
        }
    }

    $data += $entry
    $data | ConvertTo-Json -Depth 4 | Out-File $IntentFile -Encoding UTF8

    Write-IntentTranslatorLog "ðŸ§  Nouvelle phrase apprise : '$Text' â†’ $Intent"
}


# ====================================================================
# ðŸ§© Analyse du texte â†’ intention
# ====================================================================
function Convert-TextToIntent {
    param([string]$Phrase)

    Write-Host "ðŸ’¬ InterprÃ©tation du texte : $Phrase" -ForegroundColor Cyan
    $intent = "gpt_fallback"

    switch -Regex ($Phrase.ToLower()) {
        "netto(ie|yage|yer)"        { $intent = "nettoyage_json" }
        "analyse|audit|scanne"      { $intent = "audit_systeme" }
        "rÃ©pare|corrige|fixe"       { $intent = "auto_repair" }
        "apprend|learning|entraine" { $intent = "auto_learning" }
        "Ã©volue|amÃ©liore"           { $intent = "evolution_cycle" }
        "sauvegarde|backup"         { $intent = "backup_full" }
        "status|Ã©tat|statut"        { $intent = "get_status" }
        "Ã©motion|humeur"            { $intent = "sync_emotion" }
        "redÃ©marre|reboot"          { $intent = "restart_cycle" }
        "arrÃªte|stoppe"             { $intent = "shutdown_sequence" }
        default                     { $intent = "gpt_fallback" }
    }

    Learn-NewIntent -Text $Phrase -Intent $intent

    return @{ intent = $intent; payload = @{} } | ConvertTo-Json -Depth 3
}

# ====================================================================
# ðŸ§  ExÃ©cution de lâ€™intention
# ====================================================================
function Invoke-AthenaTextIntent {
    param([string]$Text)

    $json = Convert-TextToIntent -Phrase $Text
    $obj  = $json | ConvertFrom-Json

    # Envoi vers IntentBridge
    if (Get-Command Invoke-AthenaIntent -ErrorAction SilentlyContinue) {
        Write-IntentTranslatorLog "âž¡ï¸ ExÃ©cution via IntentBridge : $($obj.intent)"
        $res = Invoke-AthenaIntent -Intent $obj.intent -Payload @{}
        return $res
    } else {
        Write-Warning "âš ï¸ IntentBridge non disponible."
        return $null
    }
}

# ====================================================================
# ðŸ”„ Mise Ã  jour automatique du IntentMap.json
# ====================================================================
function Update-IntentMap {
    try {
        if (!(Test-Path $IntentFile)) { return }
        $learned = Get-Content $IntentFile -Raw | ConvertFrom-Json
        $map = @()
        if (Test-Path $IntentMap) {
            try { $map = Get-Content $IntentMap -Raw | ConvertFrom-Json } catch { $map = @() }
        }

        foreach ($e in $learned) {
            if ($map.intent -notcontains $e.intent) {
                $map += @{ pattern = $e.text; module = "Athena.Core"; function = $e.intent }
            }
        }

        $map | ConvertTo-Json -Depth 4 | Out-File $IntentMap -Encoding UTF8
        Write-IntentTranslatorLog "ðŸ§© IntentMap mis Ã  jour automatiquement."
        if (Get-Command Initialize-IntentBridge -ErrorAction SilentlyContinue) {
            Initialize-IntentBridge
        }
    } catch {
        Write-IntentTranslatorLog "âš ï¸ Erreur Update-IntentMap : $_"
    }
}

# ====================================================================
# ðŸ§® RÃ©sumÃ© rapide
# ====================================================================
function Get-IntentSummary {
    if (Test-Path $IntentFile) {
        $data = Get-Content $IntentFile -Raw | ConvertFrom-Json
        Write-Host "`nðŸ§­ Intentions connues :" -ForegroundColor Yellow
        $data | Sort-Object -Property intent | Format-Table timestamp, text, intent
    } else {
        Write-Host "Aucune phrase apprise pour le moment." -ForegroundColor DarkGray
    }
}

# ====================================================================
# ðŸ”§ RÃ©paration et synchronisation
# ====================================================================
function Repair-IntentMap {
    if (!(Test-Path $IntentMap)) { return }
    try {
        $map = Get-Content $IntentMap -Raw | ConvertFrom-Json
        $map = $map | Where-Object { $_.pattern -and $_.module -and $_.function }
        $map | ConvertTo-Json -Depth 4 | Out-File $IntentMap -Encoding UTF8
        Write-IntentTranslatorLog "âœ… IntentMap vÃ©rifiÃ© et corrigÃ©."
    } catch {
        Write-IntentTranslatorLog "âš ï¸ Erreur Repair-IntentMap : $_"
    }
}

function AutoSync-IntentBridge {
    Write-IntentTranslatorLog "ðŸ” Synchronisation IntentBridge..."
    Update-IntentMap
    Repair-IntentMap
    if (Get-Command Initialize-IntentBridge -ErrorAction SilentlyContinue) {
        Initialize-IntentBridge
    }
}

# ====================================================================
# ðŸš€ Export
# ====================================================================
Export-ModuleMember -Function Convert-TextToIntent, Invoke-AthenaTextIntent, Learn-NewIntent, Update-IntentMap, Get-IntentSummary, AutoSync-IntentBridge, Repair-IntentMap
Write-Host "âœ… Module Athena.IntentTranslator.psm1 chargÃ© (v3.0 Universal Cognitive Parser)" -ForegroundColor Green
Write-IntentTranslatorLog "Module IntentTranslator v3.0 chargÃ©."


