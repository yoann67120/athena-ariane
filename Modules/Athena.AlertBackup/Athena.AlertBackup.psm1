# ====================================================================
# ðŸ’¾ Athena.AlertBackup.psm1
# Phase 9 â€“ Alerte et sauvegarde dâ€™urgence
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleRoot
$LogsDir     = Join-Path $RootDir "Logs"
$MemoryDir   = Join-Path $RootDir "Memory"
$BackupDir   = Join-Path $RootDir "Backups"
$AudioDir    = Join-Path $RootDir "Data\Audio"

if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }

$LogFile = Join-Path $LogsDir "AthenaAlertBackup.log"

function Write-AthenaAlertBackupLog {
    param([string]$Msg, [string]$Level = "INFO")
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$time][$Level] $Msg"
}

function Invoke-AthenaAlertBackup {
    Write-Host "`nðŸ’¾ VÃ©rification des alertes et sauvegardes Athena..." -ForegroundColor Cyan
    Write-AthenaAlertBackupLog "DÃ©marrage du contrÃ´le dâ€™alerte et de sauvegarde."

    $ReportFile = Join-Path $LogsDir "AthenaReport.log"
    if (!(Test-Path $ReportFile)) {
        Write-Warning "Aucun rapport du jour trouvÃ©."
        Write-AthenaAlertBackupLog "Aucun rapport trouvÃ© â€“ arrÃªt du module." "WARN"
        return
    }

    $content = Get-Content $ReportFile -Raw
    $score = 100
    if ($content -match 'Score global : (\d+)%') {
        $score = [int]$matches[1]
    }

    Write-AthenaAlertBackupLog "Score global dÃ©tectÃ© : $score%"

    if ($score -lt 50) {
        Write-Host "âš ï¸ Score critique dÃ©tectÃ© ($score%) â€“ lancement dâ€™une sauvegarde dâ€™urgence." -ForegroundColor Yellow
        Write-AthenaAlertBackupLog "Score critique â€“ dÃ©clenchement de la sauvegarde." "ACTION"

        # CrÃ©e un dossier datÃ© pour la sauvegarde
        $dateStr = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
        $EmergencyBackupDir = Join-Path $BackupDir "Emergency_$dateStr"
        New-Item -ItemType Directory -Path $EmergencyBackupDir -Force | Out-Null

        # Sauvegarde des fichiers clÃ©s
        $files = Get-ChildItem $LogsDir -File | Where-Object { $_.Name -like "Athena*.log" }
        foreach ($f in $files) {
            Copy-Item -Path $f.FullName -Destination $EmergencyBackupDir -Force
        }

        Write-AthenaAlertBackupLog "Sauvegarde dâ€™urgence terminÃ©e dans : $EmergencyBackupDir"
        Write-Host "ðŸ’¾ Sauvegarde dâ€™urgence crÃ©Ã©e : $EmergencyBackupDir" -ForegroundColor Green

        # Alerte visuelle + sonore (si fichier prÃ©sent)
        $beepFile = Join-Path $AudioDir "k2000_beep.wav"
        if (Test-Path $beepFile) {
            try {
                $player = New-Object System.Media.SoundPlayer $beepFile
                $player.Play()
            } catch {
                Write-AthenaAlertBackupLog "Erreur lecture son : $_" "WARN"
            }
        } else {
            Write-Host "ðŸ”‡ Aucun son dÃ©tectÃ© (fichier $beepFile absent)." -ForegroundColor DarkGray
        }

        # Enregistre une alerte mÃ©moire
        $alertFile = Join-Path $MemoryDir "LastAlert.json"
        $alert = @{
            Date  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Type  = "ScoreCritique"
            Score = $score
            BackupPath = $EmergencyBackupDir
        }
        $alert | ConvertTo-Json -Depth 5 | Out-File -FilePath $alertFile -Encoding UTF8
        Write-AthenaAlertBackupLog "Alerte sauvegardÃ©e dans $alertFile"
    }
    else {
        Write-Host "âœ… Aucun problÃ¨me critique dÃ©tectÃ©. Score : $score%" -ForegroundColor Green
        Write-AthenaAlertBackupLog "Score satisfaisant â€“ aucune action requise."
    }

    Write-AthenaAlertBackupLog "Fin du module AlertBackup."
    Write-Host "ðŸ’¾ VÃ©rification des alertes terminÃ©e." -ForegroundColor Cyan
}
Export-ModuleMember -Function Invoke-AthenaAlertBackup




