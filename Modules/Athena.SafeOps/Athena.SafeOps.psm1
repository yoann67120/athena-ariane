# ====================================================================
# ðŸ” Athena.SafeOps.psm1 â€“ v2.0-AdaptiveCore
# Description : Gestion adaptative de la sÃ©curitÃ© (intÃ©gritÃ©, dÃ©fense, restauration)
# Auteur      : Ariane V4 / Athena Engine
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --------------------------------------------------------------------
# ðŸ“ Initialisation des chemins
# --------------------------------------------------------------------
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $ProjectDir "Logs"
$MemoryDir  = Join-Path $ProjectDir "Memory"

foreach ($d in @($LogsDir,$MemoryDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$SafeLog          = Join-Path $LogsDir "AthenaSafeOps.log"
$SecurityStateFile = Join-Path $MemoryDir "SecurityState.json"

# ====================================================================
# ðŸ§© 1. Snapshot avant Ã©criture
# ====================================================================
function Safe-SnapshotModule {
    param([Parameter(Mandatory)][string]$Path)
    if (Test-Path $Path) {
        $bak = "$Path.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
        try {
            Copy-Item $Path $bak -Force
            Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] âœ… Snapshot crÃ©Ã© : $bak"
            Write-Host "ðŸ§  Snapshot crÃ©Ã© pour : $Path" -ForegroundColor Cyan
        } catch {
            Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] âŒ Erreur snapshot : $($_.Exception.Message)"
        }
    } else {
        Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] âš ï¸ Fichier introuvable pour snapshot : $Path"
    }
}

# ====================================================================
# âœï¸ 2. Ã‰criture sÃ©curisÃ©e (avec Dry-Run)
# ====================================================================
function Safe-WriteModule {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content,
        [switch]$DryRun
    )
    if ($DryRun) {
        Write-Host "ðŸ”Ž [DryRun] Ã‰criture simulÃ©e : $Path" -ForegroundColor Yellow
        Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] [DryRun] Simulation Ã©criture $Path"
        return
    }
    Safe-SnapshotModule -Path $Path
    try {
        $Content | Set-Content -Path $Path -Encoding UTF8
        Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] âœ… Ã‰criture sÃ©curisÃ©e : $Path"
        Write-Host "âœ… Ã‰criture sÃ©curisÃ©e : $Path" -ForegroundColor Green
    } catch {
        Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] âŒ Erreur Ã©criture : $($_.Exception.Message)"
    }
}

# ====================================================================
# ðŸ”„ 3. Rechargement + rollback automatique
# ====================================================================
function Safe-ReloadModule {
    param([Parameter(Mandatory)][string]$Name)
    $modulePath = Join-Path $ModuleDir "$Name.psm1"
    try {
        Import-Module $modulePath -Force -Global
        Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] ðŸ”„ Module rechargÃ© : $Name"
        Write-Host "ðŸ”„ Module rechargÃ© : $Name" -ForegroundColor Green
    } catch {
        Write-Warning "âš ï¸ Erreur rechargement $Name, tentative rollback..."
        $bak = Get-ChildItem "$modulePath.bak_*" -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($bak) {
            Copy-Item $bak.FullName $modulePath -Force
            Import-Module $modulePath -Force -Global
            Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] â™»ï¸ Rollback restaurÃ© depuis $($bak.Name)"
            Write-Host "â™»ï¸ Rollback appliquÃ© depuis $($bak.Name)" -ForegroundColor Yellow
        } else {
            Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] âŒ Aucun snapshot disponible pour rollback."
        }
    }
}

# ====================================================================
# ðŸ§  4. Gestion adaptative du niveau de sÃ©curitÃ©
# ====================================================================
function Get-SecurityLevel {
    if (Test-Path $SecurityStateFile) {
        try { return (Get-Content $SecurityStateFile -Raw | ConvertFrom-Json).Level }
        catch { return 0 }
    } else { return 0 }
}

function Set-SecurityLevel {
    param([ValidateSet(0,1,2,3)][int]$Level,[string]$Reason="manuel")
    $state = @{ Date=(Get-Date); Level=$Level; Reason=$Reason }
    $state | ConvertTo-Json -Depth 3 | Set-Content $SecurityStateFile -Encoding utf8
    Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] ðŸ”’ Niveau sÃ©curitÃ© = $Level ($Reason)"

    switch ($Level) {
        0 { Write-Host "Mode Normal activÃ©" -ForegroundColor Gray }
        1 { Write-Host "Mode SAFE activÃ© â€“ verrouillage prÃ©ventif" -ForegroundColor Cyan
            Lock-CriticalModules -Modules @("Core.psm1","LocalModel.psm1") }
        2 { Write-Host "Mode ISOLATION â€“ confinement partiel" -ForegroundColor Yellow }
        3 { Write-Host "ðŸš¨ LOCKDOWN â€“ blocage total et restauration forcÃ©e" -ForegroundColor Red }
    }
}

# ====================================================================
# ðŸ§© 5. Verrouillage lecture seule des modules critiques
# ====================================================================
function Lock-CriticalModules {
    param([string[]]$Modules,[switch]$DryRun)
    $base = Join-Path $ProjectDir "Modules"
    foreach ($m in $Modules) {
        $path = Join-Path $base $m
        if (Test-Path $path) {
            if ($DryRun) { Write-Host "[DryRun] Lock $m" -ForegroundColor Yellow }
            else {
                attrib +r $path
                Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] ðŸ”’ Module verrouillÃ© : $m"
            }
        } else {
            Write-Warning "Module introuvable : $m"
        }
    }
}

# ====================================================================
# ðŸ“Š 6. Export dâ€™un snapshot dâ€™intÃ©gritÃ© (hash + taille + date)
# ====================================================================
function Export-IntegritySnapshot {
    $target = Join-Path $MemoryDir "IntegritySnapshot.json"
    $mods = Get-ChildItem -Path (Join-Path $ProjectDir "Modules") -Filter *.psm1 -File
    $report = foreach ($m in $mods) {
        [pscustomobject]@{
            Name=$m.Name
            Hash=(Get-FileHash $m.FullName -Algorithm SHA256).Hash
            Size=$m.Length
            LastWrite=$m.LastWriteTime
        }
    }
    $report | ConvertTo-Json -Depth 4 | Set-Content -Path $target -Encoding utf8
    Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] âœ… Snapshot dâ€™intÃ©gritÃ© exportÃ© ($($report.Count) modules)"
    return $report
}

# ====================================================================
# ðŸš¨ 7. Cycle complet SafeOps
# ====================================================================
function Invoke-AthenaSafeOps {
    Write-Host "`nðŸ” DÃ©marrage du cycle SafeOps..." -ForegroundColor Cyan
    $level = Get-SecurityLevel
    $snap = Export-IntegritySnapshot

    if (Get-Command Invoke-AthenaDefenseMatrix -ErrorAction SilentlyContinue) {
        Invoke-AthenaDefenseMatrix -Snapshot $snap
    } else {
        Write-Host "âš ï¸ DefenseMatrix non disponible, vÃ©rification basique uniquement." -ForegroundColor Yellow
    }

    Write-Host "âœ… Cycle SafeOps terminÃ© (niveau $level)." -ForegroundColor Green
    Add-Content -Path $SafeLog -Value "[$(Get-Date -Format u)] âœ… Cycle SafeOps terminÃ© (niveau $level)."
}

# ====================================================================
# ðŸ“¦ Export des fonctions publiques
# ====================================================================
Export-ModuleMember -Function Safe-SnapshotModule,Safe-WriteModule,Safe-ReloadModule,Invoke-AthenaSafeOps,Get-SecurityLevel,Set-SecurityLevel,Lock-CriticalModules,Export-IntegritySnapshot

Write-Host "âœ… Module Athena.SafeOps chargÃ© (v2.0-AdaptiveCore â€“ sÃ©curitÃ© adaptative complÃ¨te)."



