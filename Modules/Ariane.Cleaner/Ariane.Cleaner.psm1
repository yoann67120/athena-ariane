# Ariane.Cleaner.psm1

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

function Move-Files {
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
    $movedFilesCount = 0
    
    foreach ($file in $files) {
        $extension = $file.Extension
        $destinationFolder = $fileExtensions[$extension] -or 'Autres'
        $destinationPath = Join-Path -Path $AuditPath -ChildPath $destinationFolder
        $destinationFile = Join-Path -Path $destinationPath -ChildPath $file.Name
        
        if (-not (Test-Path -Path $destinationFile)) {
            Move-Item -Path $file.FullName -Destination $destinationPath
            $movedFilesCount++
        }
    }
    
    return $movedFilesCount
}

function Start-Audit {
    param (
        [string]$SourcePath = "$env:ARIANE_ROOT",
        [string]$AuditPath = "$env:ARIANE_ROOT_Audit"
    )
    
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Host "Le dossier source n'existe pas : $SourcePath"
        return
    }
    
    if (-not (Test-Path -Path $AuditPath)) {
        New-Item -Path $AuditPath -ItemType Directory | Out-Null
    }
    
    Initialize-AuditDirectory -AuditPath $AuditPath
    $movedFilesCount = Move-Files -SourcePath $SourcePath -AuditPath $AuditPath
    
    Write-Host "RÃ©sumÃ© :"
    Write-Host "$movedFilesCount fichiers ont Ã©tÃ© dÃ©placÃ©s."
}

Export-ModuleMember -Function Start-Audit

