# ================================
# Ariane.Cleaner.Safe.psm1
# Version sÃ©curisÃ©e : copie sans suppression
# ================================

function Initialize-AuditDirectory {
    param (
        [string]$AuditPath
    )

    $directories = @("Modules", "Scripts", "Logs", "Autres")

    foreach ($dir in $directories) {
        $fullPath = Join-Path -Path $AuditPath -ChildPath $dir
        if (-not (Test-Path -Path $fullPath)) {
            New-Item -Path $fullPath -ItemType Directory | Out-Null
        }
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

    $files = Get-ChildItem -Path $SourcePath -File
    $copiedFiles = 0
    $skippedFiles = 0

    foreach ($file in $files) {
        $extension = $file.Extension
        $destinationFolder = $fileExtensions[$extension] -or 'Autres'
        $destinationPath = Join-Path -Path $AuditPath -ChildPath $destinationFolder
        $destinationFile = Join-Path -Path $destinationPath -ChildPath $file.Name

        # Si le fichier existe dÃ©jÃ , on le saute
        if (Test-Path -Path $destinationFile) {
            Write-Host "IgnorÃ© (existe dÃ©jÃ ) : $($file.Name)" -ForegroundColor Yellow
            $skippedFiles++
            continue
        }

        # Copie sÃ©curisÃ©e
        try {
            Copy-Item -Path $file.FullName -Destination $destinationPath -ErrorAction Stop
            $copiedFiles++
        }
        catch {
            Write-Host "Erreur sur : $($file.FullName)" -ForegroundColor Red
        }
    }

    # Rapport de fin
    Write-Host "---------------------------------------------"
    Write-Host "RÃ©sumÃ© du nettoyage sÃ©curisÃ© :" -ForegroundColor Cyan
    Write-Host "  Fichiers copiÃ©s   : $copiedFiles" -ForegroundColor Green
    Write-Host "  Fichiers ignorÃ©s  : $skippedFiles" -ForegroundColor Yellow
    Write-Host "---------------------------------------------"
}

function Start-AuditSafe {
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

Export-ModuleMember -Function Start-AuditSafe


