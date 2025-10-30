# ====================================================================
# ðŸ§© Athena.Integrity.psm1 â€“ Auto-IntÃ©gritÃ© & Checkpoint
# Version : v1.0-Stable (Phase 25)
# Auteur  : Athena Core / Ariane V4
# Description :
#   VÃ©rifie la cohÃ©rence du systÃ¨me, calcule les empreintes SHA256,
#   dÃ©tecte les altÃ©rations, et restaure depuis le dernier checkpoint.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Initialisation des chemins ---
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$BackupDir  = Join-Path $RootDir "Backups"
$ConfigDir  = Join-Path $RootDir "Config"
$IntegrityLog  = Join-Path $LogsDir "Integrity.log"
$IntegrityJson = Join-Path $LogsDir "Integrity_Report.json"
$HashmapFile   = Join-Path $MemoryDir "Modules_Hashmap.json"

foreach ($p in @($LogsDir,$MemoryDir,$BackupDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# ====================================================================
# ðŸª¶ UTILITAIRE DE LOG
# ====================================================================
function Write-IntegrityLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $IntegrityLog -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ§® CARTOGRAPHIE DES FICHIERS
# ====================================================================
function Get-FileIntegrityMap {
    Write-IntegrityLog "GÃ©nÃ©ration de la carte dâ€™intÃ©gritÃ©..."
    $paths = @(
        Join-Path $RootDir "Modules",
        Join-Path $RootDir "Config",
        Join-Path $RootDir "Memory"
    )

    $data = @()
    foreach ($dir in $paths) {
        if (Test-Path $dir) {
            Get-ChildItem -Path $dir -Recurse -Include *.psm1,*.ps1,*.json -File |
            ForEach-Object {
                try {
                    $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
                    $data += [PSCustomObject]@{
                        Nom      = $_.Name
                        Chemin   = $_.FullName
                        Taille   = $_.Length
                        DateMod  = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        SHA256   = $hash
                    }
                } catch {
                    Write-IntegrityLog "Erreur lecture fichier $($_.FullName)"
                }
            }
        }
    }
    return $data
}

# ====================================================================
# ðŸ’¾ SAUVEGARDE DE LA CARTE
# ====================================================================
function Save-IntegrityMap {
    param([array]$Map)
    if ($null -eq $Map -or $Map.Count -eq 0) { return }
    $Map | ConvertTo-Json -Depth 4 | Set-Content -Path $HashmapFile -Encoding UTF8
    Write-IntegrityLog "Carte dâ€™intÃ©gritÃ© sauvegardÃ©e : $HashmapFile"
}

# ====================================================================
# ðŸ” COMPARAISON AVEC LA CARTE PRÃ‰CÃ‰DENTE
# ====================================================================
function Compare-IntegrityMap {
    param([array]$NewMap)

    $OldMap = @()
    if (Test-Path $HashmapFile) {
        try { $OldMap = Get-Content $HashmapFile -Raw | ConvertFrom-Json } catch {}
    }

    $diff = @()
    foreach ($file in $NewMap) {
        $match = $OldMap | Where-Object { $_.Chemin -eq $file.Chemin }
        if (-not $match) {
            $diff += [PSCustomObject]@{ Fichier=$file.Nom; Etat="New" }
        } elseif ($match.SHA256 -ne $file.SHA256) {
            $diff += [PSCustomObject]@{ Fichier=$file.Nom; Etat="Changed" }
        } else {
            $diff += [PSCustomObject]@{ Fichier=$file.Nom; Etat="OK" }
        }
    }

    # fichiers supprimÃ©s
    foreach ($old in $OldMap) {
        if (-not ($NewMap | Where-Object { $_.Chemin -eq $old.Chemin })) {
            $diff += [PSCustomObject]@{ Fichier=$old.Nom; Etat="Missing" }
        }
    }

    return $diff
}

# ====================================================================
# ðŸ§  CHECKPOINT (sauvegarde mensuelle)
# ====================================================================
function New-AthenaCheckpoint {
    $date = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $zipPath = Join-Path $BackupDir "Checkpoint_$date.zip"
    $items = @("Modules","Config","Memory") | ForEach-Object { Join-Path $RootDir $_ }

    try {
        Compress-Archive -Path $items -DestinationPath $zipPath -Force
        Write-IntegrityLog "Checkpoint crÃ©Ã© : $zipPath"
        Write-Host "ðŸ’¾ Checkpoint sauvegardÃ© : $zipPath" -ForegroundColor Cyan
    } catch {
        Write-IntegrityLog "Erreur crÃ©ation checkpoint : $_"
        Write-Warning "âŒ Erreur durant la crÃ©ation du checkpoint."
    }

    return $zipPath
}

# ====================================================================
# ðŸ” RÃ‰CUPÃ‰RATION DEPUIS LE CHECKPOINT
# ====================================================================
function Restore-FromCheckpoint {
    $lastZip = Get-ChildItem -Path $BackupDir -Filter "Checkpoint_*.zip" |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $lastZip) {
        Write-Warning "âš ï¸ Aucun checkpoint trouvÃ©."
        Write-IntegrityLog "Aucun checkpoint disponible."
        return
    }

    Write-Host "â™»ï¸ Restauration depuis : $($lastZip.Name)" -ForegroundColor Yellow
    try {
        Expand-Archive -Path $lastZip.FullName -DestinationPath $RootDir -Force
        Write-IntegrityLog "Restauration effectuÃ©e depuis $($lastZip.Name)"
        Write-Host "âœ… Restauration terminÃ©e." -ForegroundColor Green
    } catch {
        Write-Warning "âŒ Ã‰chec restauration : $_"
        Write-IntegrityLog "Erreur restauration : $_"
    }
}

# ====================================================================
# ðŸ”Ž FONCTION PRINCIPALE â€“ INVOKE-ATHENAINTEGRITY
# ====================================================================
function Invoke-AthenaIntegrity {
    [CmdletBinding()] param([switch]$Checkpoint)

    Write-Host "`nðŸ” DÃ©marrage du contrÃ´le dâ€™intÃ©gritÃ© Athena..." -ForegroundColor Cyan
    Write-IntegrityLog "=== VÃ©rification lancÃ©e $(Get-Date -Format 'u') ==="

    if ($Checkpoint) {
        $zip = New-AthenaCheckpoint
        Write-IntegrityLog "Checkpoint manuel exÃ©cutÃ© : $zip"
        return
    }

    $map = Get-FileIntegrityMap
    $diff = Compare-IntegrityMap -NewMap $map

    # --- RÃ©sumÃ© ---
    $summary = @{
        Date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        RÃ©sultats = $diff
    }

    $summary | ConvertTo-Json -Depth 4 | Out-File -FilePath $IntegrityJson -Encoding utf8
    Write-IntegrityLog "Rapport sauvegardÃ© : $IntegrityJson"

    $changed = ($diff | Where-Object { $_.Etat -eq "Changed" }).Count
    $missing = ($diff | Where-Object { $_.Etat -eq "Missing" }).Count

    if ($changed -eq 0 -and $missing -eq 0) {
        Write-Host "âœ… Structure intacte â€“ aucun correctif nÃ©cessaire." -ForegroundColor Green
        Write-IntegrityLog "Structure OK â€“ aucun correctif."
    } else {
        Write-Warning "âš ï¸ Anomalies dÃ©tectÃ©es : Changed=$changed, Missing=$missing"
        Write-IntegrityLog "Anomalies dÃ©tectÃ©es : $changed modifiÃ©s, $missing manquants"

        # --- Tentative AutoPatch ---
        if (Get-Command Invoke-AutoPatch -ErrorAction SilentlyContinue) {
            try {
                Write-Host "ðŸ”§ Tentative AutoPatch..." -ForegroundColor Yellow
                Invoke-AutoPatch | Out-Null
                Write-IntegrityLog "AutoPatch appelÃ© automatiquement."
            } catch {
                Write-IntegrityLog "AutoPatch Ã©chec : $_"
                Write-Warning "âŒ AutoPatch a Ã©chouÃ©, tentative de restauration..."
                Restore-FromCheckpoint
            }
        } else {
            Write-Warning "âš™ï¸ AutoPatch non disponible â€“ restauration directe."
            Restore-FromCheckpoint
        }
    }

    Save-IntegrityMap -Map $map
    Write-Host "ðŸ“˜ Rapport final : $IntegrityJson" -ForegroundColor Cyan
}

# ====================================================================
# ðŸ“¤ EXPORT DES FONCTIONS
# ====================================================================
Export-ModuleMember -Function `
    Invoke-AthenaIntegrity, `
    New-AthenaCheckpoint, `
    Restore-FromCheckpoint, `
    Get-FileIntegrityMap, `
    Compare-IntegrityMap



