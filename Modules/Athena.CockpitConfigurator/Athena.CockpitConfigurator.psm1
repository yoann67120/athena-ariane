# ====================================================================
# âš™ï¸ Athena.CockpitConfigurator.psm1
# Version : v1.0-FullAuto-Setup-Stable
# Auteur  : Projet Ariane V4 / Athena Core
# RÃ´le   : Configuration et autogestion complÃ¨te du Cockpit Ariane
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Dossiers racine ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$ModulesDir = Join-Path $RootDir "Modules"
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$WebUIDir   = Join-Path $RootDir "WebUI"

if (!(Test-Path $LogsDir))   { New-Item -ItemType Directory -Force -Path $LogsDir   | Out-Null }
if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Force -Path $MemoryDir | Out-Null }

$LogFile = Join-Path $LogsDir "CockpitConfigurator.log"

function Write-CockpitConfigLog {
    param([string]$Msg,[string]$Level="INFO")
    $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ” VÃ©rification des dÃ©pendances Cockpit
# ====================================================================
function Test-CockpitModules {
    Write-Host "\nðŸ” VÃ©rification des modules Cockpit..." -ForegroundColor Cyan
    $required = @(
        'Cockpit.Server.psm1','Cockpit.SocketServer.psm1','Cockpit.Sync.psm1','Cockpit.Signal.psm1',
        'Athena.Dialogue.psm1','Athena.Feedback.psm1','Athena.Voice.psm1','Athena.Engine.psm1'
    )
    $missing = @()
    foreach ($m in $required) {
        $path = Join-Path $ModulesDir $m
        if (!(Test-Path $path)) { $missing += $m }
    }
    if ($missing.Count -gt 0) {
        Write-Warning "Modules manquants : $($missing -join ', ')"
        Write-CockpitConfigLog "Modules manquants : $($missing -join ', ')" "WARN"
    } else {
        Write-Host "âœ… Tous les modules Cockpit sont prÃ©sents." -ForegroundColor Green
    }
}

# ====================================================================
# ðŸ§  Chargement automatique des modules nÃ©cessaires
# ====================================================================
function Load-CockpitModules {
    Write-Host "\nðŸ“¦ Chargement des modules Cockpit..." -ForegroundColor Cyan
    Get-ChildItem $ModulesDir -Filter 'Cockpit*.psm1' | ForEach-Object {
        try {
            Import-Module $_.FullName -Force -Global -ErrorAction Stop
            Write-Host "âœ… Module chargÃ© : $($_.Name)" -ForegroundColor Green
        } catch {
            Write-Warning "âš ï¸ Erreur de chargement : $($_.Name)"
            Write-CockpitConfigLog "Erreur chargement module : $($_.Name) -> $_" "ERROR"
        }
    }
}

# ====================================================================
# ðŸš€ Initialisation complÃ¨te du Cockpit (serveur + socket + sync)
# ====================================================================
function Initialize-CockpitFull {
    Write-Host "\nðŸš€ Initialisation automatique du Cockpit..." -ForegroundColor Cyan
    Write-CockpitConfigLog "Initialisation Cockpit complÃ¨te."

    Test-CockpitModules
    Load-CockpitModules

    # --- Serveur principal ---
    try {
        if (Get-Command Start-CockpitServer -ErrorAction SilentlyContinue) {
            Start-CockpitServer -Port 9191 | Out-Null
            Write-Host "ðŸŒ Serveur Cockpit HTTP actif sur port 9191" -ForegroundColor Green
        }
    } catch {
        Write-Warning "âš ï¸ Erreur lancement serveur Cockpit : $_"
    }

    # --- WebSocket ---
    try {
        if (Get-Command Start-CockpitSocketServer -ErrorAction SilentlyContinue) {
            Start-CockpitSocketServer | Out-Null
            Write-Host "ðŸ›°ï¸ Serveur WebSocket Cockpit actif." -ForegroundColor Green
        }
    } catch {
        Write-Warning "âš ï¸ Erreur lancement WebSocket : $_"
    }

    # --- Synchronisation ---
    try {
        if (Get-Command Initialize-CockpitSync -ErrorAction SilentlyContinue) {
            Initialize-CockpitSync | Out-Null
            Write-Host "ðŸ”„ Synchronisation Cockpit active." -ForegroundColor Green
        }
    } catch {
        Write-Warning "âš ï¸ Erreur lancement synchronisation : $_"
    }

    # --- Signal et feedback ---
    if (Get-Command Set-CockpitMood -ErrorAction SilentlyContinue) {
        Set-CockpitMood -Mood "satisfaite" -State "SÃ©rÃ©nitÃ©" -Message "Cockpit prÃªt." | Out-Null
    }

    Write-Host "\nâœ… Cockpit opÃ©rationnel (Chat, Boutons, Feedback actifs)" -ForegroundColor Green
    Write-CockpitConfigLog "Cockpit prÃªt et opÃ©rationnel."
}

# ====================================================================
# ðŸ” RedÃ©marrage complet du Cockpit
# ====================================================================
function Restart-CockpitFull {
    Write-Host "\nâ™»ï¸ RedÃ©marrage complet du Cockpit..." -ForegroundColor Yellow
    if (Get-Command Stop-CockpitSocketServer -ErrorAction SilentlyContinue) { Stop-CockpitSocketServer }
    if (Get-Command Stop-CockpitServer -ErrorAction SilentlyContinue) { Stop-CockpitServer }
    Start-Sleep -Seconds 2
    Initialize-CockpitFull
}

# ====================================================================
# ðŸ§ª Test de connexion et d'intÃ©gritÃ©
# ====================================================================
function Test-CockpitIntegrity {
    Write-Host "\nðŸ§ª Test de l'intÃ©gritÃ© du Cockpit..." -ForegroundColor Yellow
    $ok = $false
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:9191" -UseBasicParsing -TimeoutSec 3
        if ($resp.StatusCode -eq 200) { $ok = $true }
    } catch {}

    if ($ok) {
        Write-Host "âœ… Cockpit rÃ©pond sur le port 9191." -ForegroundColor Green
    } else {
        Write-Warning "âš ï¸ Cockpit inactif, redÃ©marrage automatique."
        Restart-CockpitFull
    }
}

# ====================================================================
# ðŸ§  Auto-surveillance continue
# ====================================================================
function Monitor-CockpitStatus {
    Write-Host "\nðŸ§© DÃ©marrage de la surveillance Cockpit (30s)..." -ForegroundColor Cyan
    Start-Job -Name "CockpitMonitor" -ScriptBlock {
        while ($true) {
            try {
                $resp = Invoke-WebRequest -Uri "http://localhost:9191" -UseBasicParsing -TimeoutSec 3
                if ($resp.StatusCode -ne 200) { Restart-CockpitFull }
            } catch { Restart-CockpitFull }
            Start-Sleep -Seconds 30
        }
    } | Out-Null
}

# ====================================================================
# ðŸ§¾ Export des fonctions publiques
# ====================================================================
Export-ModuleMember -Function Initialize-CockpitFull, Restart-CockpitFull, Test-CockpitIntegrity, Monitor-CockpitStatus

Write-Host "âš™ï¸ Module Athena.CockpitConfigurator.psm1 chargÃ© (v1.0-FullAuto-Setup-Stable)." -ForegroundColor Cyan
Write-CockpitConfigLog "Module Athena.CockpitConfigurator.psm1 chargÃ© (v1.0-FullAuto-Setup-Stable)."


