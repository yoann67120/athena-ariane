# ================================
# Ariane.Cleaner.Safe.v2.psm1
# Copie rÃ©cursive + rapport complet
# ================================

function Initialize-AuditDirectory {
    param ([string]$AuditPath)

    $directories = @("Modules", "Scripts", "Logs", "Autres")

    foreach ($dir in $directories) {
        $fullPath = Join-Path -Path $AuditPath -ChildPath $dir
        if (-not (Test-Path -Path $fullPath)) {
            New-Item -Path $fullPath -ItemType Directory | Out-Null
        }
    }

    # Dossier pour logs
    $logDir = Join-Path -Path $AuditPath -ChildPath "Logs"
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory | Out-Null
    }
}

function Copy-FilesSafely {
    param (
        [string]$SourcePath,
        [string]$AuditPath
    )

    $fileExtensions = @{
        '.psm1' = 'Modules'
        '.ps1'  = 'Scripts'
        '.log'  = 'Logs'
    }

    $logFile = Join-Path -Path $AuditPath -ChildPath "Logs\CleanerReport.log"
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "===== Rapport du nettoyage sÃ©curisÃ© ($timestamp) =====" | Out-File -FilePath $logFile -Encoding utf8 -Append

    $files = Get-ChildItem -Path $SourcePath -Recurse -File -ErrorAction SilentlyContinue
    $copiedFiles = 0
    $skippedFiles = 0
    $errors = 0

    foreach ($file in $files) {
        $extension = $file.Extension
        $destinationFolder = $fileExtensions[$extension] -or 'Autres'
        $destinationPath = Join-Path -Path $AuditPath -ChildPath $destinationFolder
        $destinationFile = Join-Path -Path $destinationPath -ChildPath $file.Name

        if (Test-Path -Path $destinationFile) {
            "IgnorÃ© (existe dÃ©jÃ ) : $($file.FullName)" | Out-File -FilePath $logFile -Append
            $skippedFiles++
            continue
        }

        try {
            Copy-Item -Path $file.FullName -Destination $destinationPath -ErrorAction Stop
            "CopiÃ© : $($file.FullName)" | Out-File -FilePath $logFile -Append
            $copiedFiles++
        }
        catch {
            "Erreur sur : $($file.FullName)" | Out-File -FilePath $logFile -Append
            $errors++
        }
    }

    "---------------------------------------------" | Out-File -FilePath $logFile -Append
    "Fichiers copiÃ©s   : $copiedFiles" | Out-File -FilePath $logFile -Append
    "Fichiers ignorÃ©s  : $skippedFiles" | Out-File -FilePath $logFile -Append
    "Erreurs rencontrÃ©es : $errors" | Out-File -FilePath $logFile -Append
    "---------------------------------------------" | Out-File -FilePath $logFile -Append

    Write-Host "---------------------------------------------"
    Write-Host "RÃ©sumÃ© du nettoyage sÃ©curisÃ© (v2) :" -ForegroundColor Cyan
    Write-Host "  Fichiers copiÃ©s   : $copiedFiles" -ForegroundColor Green
    Write-Host "  Fichiers ignorÃ©s  : $skippedFiles" -ForegroundColor Yellow
    Write-Host "  Erreurs            : $errors" -ForegroundColor Red
    Write-Host "---------------------------------------------"
    Write-Host "Rapport complet : $logFile" -ForegroundColor Gray
}

function Start-AuditSafeV2 {
    param (
        [string]$SourcePath = "$env:ARIANE_ROOT",
        [string]$AuditPath = "$env:ARIANE_ROOT_Audit"
    )

    if (-not (Test-Path -Path $SourcePath)) {
        Write-Host "Le dossier source n'existe pas : $SourcePath" -ForegroundColor Red
        return
    }

    if (-not (Test-Path -Path $AuditPath)) {
        New-Item -Path $AuditPath -ItemType Directory | Out-Null
    }

    Initialize-AuditDirectory -AuditPath $AuditPath
    Copy-FilesSafely -SourcePath $SourcePath -AuditPath $AuditPath
}

Export-ModuleMember -Function Start-AuditSafeV2


