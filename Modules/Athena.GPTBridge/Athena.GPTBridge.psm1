# ====================================================================
# 🧠 Athena.GPTBridge.psm1 — v1.0 Stable
# Auteur : Yoann Rousselle / Projet Ariane V4
# Objectif :
#   - Créer la boucle complète GPT ↔ Athena ↔ GPT
#   - Relier le moteur PowerShell à AthenaLink.Hub.js
#   - Synchroniser les fichiers d’ordres et les résultats
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === Dossiers de base ===
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$ServerDir  = Join-Path $RootDir "Server"
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$InboxDir   = Join-Path $ServerDir "Memory\InboxGPT"

# === Fichiers ===
$LogFile     = Join-Path $LogsDir "GPTBridge.log"
$ActionFile  = Join-Path $MemoryDir "action_gpt.json"
$ResultFile  = Join-Path $MemoryDir "action_gpt.json.result"

# === Configuration ===
$HubUrl = "http://localhost:9191"
$BridgeInterval = 30 # secondes

# === Fonctions utilitaires ===
function Write-GPTLog {
    param([string]$msg,[string]$level="INFO")
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$time][$level] $msg"
    Add-Content -Path $LogFile -Value $line
    Write-Host $line
}

function Send-ToHub {
    param([string]$endpoint, [hashtable]$data)
    try {
        $json = $data | ConvertTo-Json -Depth 5
        Invoke-RestMethod -Uri "$HubUrl/$endpoint" -Method POST -Body $json -ContentType "application/json" -TimeoutSec 20 | Out-Null
        Write-GPTLog "📤 Sent to Hub → /$endpoint"
    } catch {
        Write-GPTLog "❌ Hub send failed: $($_.Exception.Message)" "ERROR"
    }
}

# === Envoi d’un ordre au Hub ===
function Invoke-GPTCommand {
    param(
        [Parameter(Mandatory)][string]$Action,
        [hashtable]$Param = @{},
        [string]$Source = "Athena"
    )

    $payload = @{
        action = $Action
        param  = $Param
        source = $Source
    }

    try {
        $json = $payload | ConvertTo-Json -Depth 5
        Set-Content -Path $ActionFile -Value $json -Encoding UTF8
        Write-GPTLog "🧠 New GPT Action saved: $Action"
        Send-ToHub "gpt/ingest" @{ filename = "action_gpt.json"; content = $json }
    } catch {
        Write-GPTLog "❌ Failed to send action: $($_.Exception.Message)" "ERROR"
    }
}

# === Vérifie les nouveaux résultats depuis GPT ===
function Sync-GPTResults {
    try {
        if (Test-Path $ResultFile) {
            $content = Get-Content -Path $ResultFile -Raw -ErrorAction SilentlyContinue
            if ($content -and $content.Trim() -ne "") {
                $json = $content | ConvertFrom-Json
                Write-GPTLog "📥 Result reçu: $($json.action) → $($json.status)"
                Send-ToHub "gpt/result" ($json | ConvertTo-Json -Depth 5 | ConvertFrom-Json -AsHashtable)

                Remove-Item -Path $ResultFile -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-GPTLog "❌ Erreur lecture result: $($_.Exception.Message)" "ERROR"
    }
}

# === Boucle principale de synchronisation ===
function Start-GPTBridgeLoop {
    Write-Host "`n🧠 Démarrage de la boucle GPTBridge (v1.0 Stable)..." -ForegroundColor Cyan
    Write-GPTLog "GPTBridge Loop started."

    while ($true) {
        try {
            Sync-GPTResults
        } catch {
            Write-GPTLog "Loop error: $($_.Exception.Message)" "ERROR"
        }
        Start-Sleep -Seconds $BridgeInterval
    }
}

# === Test manuel (diagnostic rapide) ===
function Test-GPTBridge {
    Write-Host "`n🔍 Test GPTBridge..." -ForegroundColor Yellow
    Invoke-GPTCommand -Action "get-date" -Param @{ } -Source "GPTBridge-Test"
}

# === Export des fonctions ===
Export-ModuleMember -Function Invoke-GPTCommand, Start-GPTBridgeLoop, Test-GPTBridge

Write-Host "🧠 Module Athena.GPTBridge.psm1 chargé (v1.0 Stable)" -ForegroundColor Green
Write-GPTLog "Module loaded (v1.0 Stable)."


