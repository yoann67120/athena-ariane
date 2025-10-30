# ====================================================================
# ðŸ§© Athena.SelfRegulation.psm1 â€“ Moteur dâ€™autorÃ©gulation adaptative
# Version : v1.1-Autonomic-Balance-Fix
# ====================================================================
# Objectif :
#   - Surveiller lâ€™Ã©tat Ã©motionnel dâ€™Athena
#   - RÃ©guler charge, prioritÃ©s, dÃ©lais et apprentissage
#   - DÃ©clencher des actions selon humeur
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir "Logs"
$RegLog    = Join-Path $LogsDir "AthenaSelfRegulation.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-RegLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $RegLog -Value "[$t] $Msg"
}

# --------------------------------------------------------------------
# ðŸ” Lecture de lâ€™Ã©tat Ã©motionnel actuel
# --------------------------------------------------------------------
function Get-AthenaState {
    $mood = "calme"
    try {
        if (Get-Command Get-AthenaEmotion -ErrorAction SilentlyContinue) {
            $mood = Get-AthenaEmotion
        } elseif (Get-Command Invoke-AthenaEmotion -ErrorAction SilentlyContinue) {
            Invoke-AthenaEmotion | Out-Null
            $mood = "calme"
        }
    } catch {
        Write-RegLog "Erreur rÃ©cupÃ©ration humeur : $_"
    }
    Write-RegLog "Ã‰tat Ã©motionnel dÃ©tectÃ© : $mood"
    return $mood
}

# --------------------------------------------------------------------
# âš™ï¸ Moteur dâ€™autorÃ©gulation principal
# --------------------------------------------------------------------
function Invoke-AthenaSelfRegulation {
    Write-Host "`nðŸ” DÃ©marrage du moteur dâ€™autorÃ©gulation..." -ForegroundColor Cyan
    $mood = Get-AthenaState
    Write-RegLog "Analyse de lâ€™humeur : $mood"

    switch ($mood) {
        "calme" {
            Write-Host "ðŸ’¤ SystÃ¨me stable. Aucun ajustement requis." -ForegroundColor Green
            Write-RegLog "Ajustement : Aucun (Ã©tat calme)."
        }
        "attentive" {
            Write-Host "ðŸ§­ Surveillance accrue et rÃ©duction des dÃ©lais." -ForegroundColor Yellow
            $global:ArianeCycleDelay = 90
            Write-RegLog "Ajustement : DÃ©lai rÃ©duit Ã  90s (attentive)."
        }
        "inquiÃ¨te" {
            Write-Host "âš ï¸ Anomalies dÃ©tectÃ©es : extension de surveillance + logs Ã©tendus." -ForegroundColor Red
            $global:ArianeExtendedLogs = $true
            Write-RegLog "Ajustement : Logs Ã©tendus (Ã©tat inquiÃ¨te)."
        }
        "critique" {
            Write-Host "ðŸš¨ Alerte critique : lancement du module SelfRepair..." -ForegroundColor Magenta
            $repair = Join-Path $RootDir "Modules\Athena.SelfRepair.psm1"
            if (Test-Path $repair) {
                Import-Module $repair -Force -Global
                Invoke-AthenaSelfRepair
                Write-RegLog "Ajustement : Cycle SelfRepair dÃ©clenchÃ©."
            }
        }
        "fatiguee" {
            Write-Host "ðŸ•¯ï¸ Pause Ã©nergÃ©tique temporaire (120 sec)..." -ForegroundColor DarkGray
            Write-RegLog "Ajustement : Pause 120s (fatiguÃ©e)."
            Start-Sleep -Seconds 120
        }
        "curieuse" {
            Write-Host "ðŸ”¬ CuriositÃ© dÃ©tectÃ©e : apprentissage contextuel relancÃ©..." -ForegroundColor Blue
            $learn = Join-Path $RootDir "Modules\Athena.Learning.psm1"
            if (Test-Path $learn) {
                Import-Module $learn -Force -Global
                Invoke-AthenaLearning
                Write-RegLog "Ajustement : Relance du module Learning."
            }
        }
        default {
            Write-RegLog "Aucun ajustement spÃ©cifique pour humeur : $mood"
        }
    }

    Write-Host "âœ… AutorÃ©gulation terminÃ©e." -ForegroundColor Green
    Write-RegLog "Cycle dâ€™autorÃ©gulation complÃ©tÃ©."
}

# --------------------------------------------------------------------
# ðŸ§ª Test manuel du module
# --------------------------------------------------------------------
function Test-AthenaSelfRegulation {
    Write-Host "`nðŸ§ª Test du moteur SelfRegulation..." -ForegroundColor Cyan
    foreach ($state in "calme","attentive","inquiÃ¨te","critique","fatiguee","curieuse") {
        Write-Host "`nâ†’ Simulation humeur : $state" -ForegroundColor Yellow
        Set-Variable -Name "fakeMood" -Value $state -Scope Global
        Invoke-AthenaSelfRegulation
        Start-Sleep -Seconds 1
    }
    Write-Host "âœ… Test complet exÃ©cutÃ©." -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-AthenaSelfRegulation, Get-AthenaState, Test-AthenaSelfRegulation
Write-Host "ðŸ§© Module Athena.SelfRegulation.psm1 chargÃ© (v1.1-Autonomic-Balance-Fix)." -ForegroundColor Cyan
Write-RegLog "Module chargÃ© (v1.1-Autonomic-Balance-Fix)."




