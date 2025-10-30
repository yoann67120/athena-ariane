# ====================================================================
# ðŸ§¹ Athena.MemoryOptimizer.psm1 (v1.0-Internal-Defrag-Engine)
# Objectif : Optimiser, dÃ©dupliquer et compacter les fichiers mÃ©moire dâ€™Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === Dossiers de travail ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ModuleRoot
$MemoryDir   = Join-Path $ProjectRoot 'Memory'
$LogsDir     = Join-Path $ProjectRoot 'Logs'
$LogFile     = Join-Path $LogsDir 'AthenaMemoryOptimizer.log'

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null }
if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Force -Path $MemoryDir | Out-Null }

# ====================================================================
# ðŸ”¹ Lecture et nettoyage basique des fichiers JSON
# ====================================================================
function Clean-MemoryFiles {
    Write-Host "ðŸ§¹ Nettoyage de base des fichiers mÃ©moire..." -ForegroundColor Cyan

    $files = Get-ChildItem -Path $MemoryDir -Filter '*.json' -File
    foreach ($f in $files) {
        try {
            $content = Get-Content $f.FullName -Raw
            $content = $content -replace '\\u0000','' -replace '\r','' -replace '\n',' ' -replace '\s{2,}',' '
            $content | Out-File $f.FullName -Encoding utf8
        } catch {
            Write-Warning "âš ï¸ Erreur lors du nettoyage de $($f.Name)"
        }
    }
    Write-Host "âœ… Nettoyage basique terminÃ©." -ForegroundColor Green
}

# ====================================================================
# ðŸ”¹ DÃ©duplication interne des entrÃ©es
# ====================================================================
function Remove-DuplicateEntries {
    param([string]$FilePath)

    try {
        $data = Get-Content $FilePath -Raw | ConvertFrom-Json
        if ($data -is [array]) {
            $unique = $data | Sort-Object -Property Timestamp -Unique
            if ((@($unique).Count) -ne (@($data).Count)) {
                $unique | ConvertTo-Json -Depth 4 | Out-File $FilePath -Encoding utf8
                Write-Host "â™»ï¸ DÃ©duplication appliquÃ©e Ã  $([System.IO.Path]::GetFileName($FilePath))" -ForegroundColor DarkGray
            }
        }
    } catch {
        Write-Warning "âš ï¸ Impossible de dÃ©dupliquer $FilePath"
    }
}

# ====================================================================
# ðŸ”¹ Compactage global (rÃ©duction taille)
# ====================================================================
function Compact-MemoryFiles {
    Write-Host "ðŸ§  Compactage des fichiers mÃ©moire..." -ForegroundColor Cyan

    $files = Get-ChildItem -Path $MemoryDir -Filter '*.json' -File
    foreach ($f in $files) {
        try {
            $content = Get-Content $f.FullName -Raw | ConvertFrom-Json | ConvertTo-Json -Compress -Depth 4
            $content | Out-File $f.FullName -Encoding utf8
        } catch {
            Write-Warning "âš ï¸ Erreur pendant le compactage de $($f.Name)"
        }
    }
    Write-Host "âœ… Compactage terminÃ©." -ForegroundColor Green
}

# ====================================================================
# ðŸ”¹ Fonction principale : Invoke-AthenaMemoryOptimizer
# ====================================================================
function Invoke-AthenaMemoryOptimizer {
    Write-Host "`nðŸ§¹ Phase 17.1 â€“ Optimisation interne de la mÃ©moire..." -ForegroundColor Cyan

    Clean-MemoryFiles

    $jsonFiles = Get-ChildItem -Path $MemoryDir -Filter '*.json' -File
    foreach ($file in $jsonFiles) {
        Remove-DuplicateEntries -FilePath $file.FullName
    }

    Compact-MemoryFiles

    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'u') | Optimisation mÃ©moire complÃ¨te exÃ©cutÃ©e ($((@($jsonFiles).Count)) fichiers traitÃ©s)."
    Write-Host "âœ… MÃ©moire interne optimisÃ©e avec succÃ¨s.`n" -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-AthenaMemoryOptimizer




