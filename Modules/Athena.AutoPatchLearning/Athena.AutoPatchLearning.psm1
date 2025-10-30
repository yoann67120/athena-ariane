# ====================================================================
# ðŸ¤– Athena.AutoPatchLearning.psm1 â€“ v1.2 Smart Threshold Build (fusion stable)
# ====================================================================
# Objectif :
#   - Analyser les rapports dâ€™Ã©volution (SelfEvolution)
#   - DÃ©tecter les modules modifiÃ©s, supprimÃ©s, ou instables
#   - DÃ©clencher un AutoPatch seulement si lâ€™anomalie persiste
#     sur plusieurs cycles (seuil de confiance)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir    = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ModulesDir = Join-Path $RootDir "Modules"
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"

foreach ($p in @($LogsDir, $MemoryDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

$LogFile    = Join-Path $LogsDir "AutoPatchLearning.log"
$DiffReport = Join-Path $MemoryDir "SelfEvolutionDiff.json"
$LearningDB = Join-Path $MemoryDir "AutoPatchLearning.json"
$Threshold  = 2   # nombre minimum de cycles consÃ©cutifs avant action

# ====================================================================
# ðŸ§  Moteur principal : Invoke-AthenaAutoPatchLearning
# ====================================================================
function Invoke-AthenaAutoPatchLearning {
    Write-Host "`nðŸ§  DÃ©marrage du moteur AutoPatch Learning (Smart Threshold)..." -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value "`n=== Cycle lancÃ© $(Get-Date -Format u) ==="

    # VÃ©rification des rapports dâ€™Ã©volution
    if (!(Test-Path $DiffReport)) {
        Write-Warning "âš ï¸ Aucun rapport comparatif trouvÃ© ($DiffReport)"
        Add-Content -Path $LogFile -Value "âš ï¸ Aucun rapport comparatif dÃ©tectÃ©."
        return
    }

    try {
        $diff = Get-Content $DiffReport -Raw | ConvertFrom-Json
        $ajoutes   = @($diff.Modules_Ajoutes)
        $supprimes = @($diff.Modules_Supprimes)
        $modifies  = @($diff.Modules_Modifies)
        $toRepair  = @($supprimes + $modifies) | Where-Object { $_ -like "Athena.*.psm1" }

        Write-Host "ðŸ“Š Analyse comparative : AjoutÃ©s=$($ajoutes.Count) SupprimÃ©s=$($supprimes.Count) ModifiÃ©s=$($modifies.Count)" -ForegroundColor Yellow
        if ($toRepair.Count -eq 0) {
            Write-Host "âœ… Aucun module Ã  surveiller pour ce cycle." -ForegroundColor Green
            Add-Content -Path $LogFile -Value "Cycle stable â€“ aucun module Ã  rÃ©parer."
            return
        }

        # ðŸ”Ž Lecture de lâ€™historique
        $history = @()
        if (Test-Path $LearningDB) {
            try { $history = Get-Content $LearningDB -Raw | ConvertFrom-Json } catch {}
        }

        $now = Get-Date
        $patchQueue = @()

        foreach ($mod in $toRepair) {
            $entries = $history | Where-Object { $_.Actions_Ciblees -contains $mod }
            $count = ($entries | Sort-Object Date -Descending | Select-Object -First $Threshold).Count

            if ($count -ge $Threshold) {
                Write-Host "âš ï¸ Anomalie persistante dÃ©tectÃ©e sur $mod ($count cycles) â†’ rÃ©paration autorisÃ©e." -ForegroundColor Yellow
                $patchQueue += $mod
            }
            else {
                Write-Host "â³ $mod dÃ©tectÃ© mais sous le seuil ($count/$Threshold cycles) â†’ observation prolongÃ©e." -ForegroundColor DarkGray
            }
        }

        # ðŸ”§ DÃ©clenchement AutoPatch si nÃ©cessaire
        if ($patchQueue.Count -gt 0) {
            Import-Module (Join-Path $ModulesDir "AutoPatch.psm1") -Force -Global | Out-Null
            foreach ($target in $patchQueue) {
                try {
                    Write-Host "ðŸ”§ AutoPatch ciblÃ© pour $target..." -ForegroundColor Cyan
                    Invoke-AutoPatch
                    Add-Content -Path $LogFile -Value "AutoPatch exÃ©cutÃ© pour $target"
                } catch {
                    Write-Warning "âš ï¸ Ã‰chec du patch pour $target : $_"
                    Add-Content -Path $LogFile -Value "Ã‰chec du patch pour $target"
                }
            }
        }
        else {
            Add-Content -Path $LogFile -Value "Aucune rÃ©paration exÃ©cutÃ©e â€“ seuil non atteint."
        }

        # ðŸ“š Enregistrement du cycle dâ€™apprentissage
        $entry = [PSCustomObject]@{
            Date             = $now
            Modules_Ajoutes   = $ajoutes
            Modules_Supprimes = $supprimes
            Modules_Modifies  = $modifies
            Actions_Ciblees   = $toRepair
        }
        $all = @($history + $entry)
        $all | ConvertTo-Json -Depth 5 | Out-File $LearningDB -Encoding utf8

        Write-Host "ðŸ’¾ Base dâ€™apprentissage mise Ã  jour : $LearningDB" -ForegroundColor Green
        Add-Content -Path $LogFile -Value "Cycle terminÃ© : seuil=$Threshold, patches=$($patchQueue.Count)"
        Write-Host "âœ… AutoPatch Learning intelligent terminÃ©." -ForegroundColor Cyan
    }
    catch {
        Write-Warning "âš ï¸ Erreur durant AutoPatch Learning : $_"
        Add-Content -Path $LogFile -Value "Erreur : $_"
    }
}

# ====================================================================
# ðŸ§ª Test manuel du moteur
# ====================================================================
function Test-AthenaAutoPatchLearning {
    Write-Host "`nðŸ§ª Test du moteur AutoPatch Learning..." -ForegroundColor Yellow
    Invoke-AthenaAutoPatchLearning
    Write-Host "âœ… Test terminÃ© â€“ consulte Logs\AutoPatchLearning.log et Memory\AutoPatchLearning.json" -ForegroundColor Green
}

# ====================================================================
# ðŸ“¤ Export des fonctions principales
# ====================================================================
Export-ModuleMember -Function Invoke-AthenaAutoPatchLearning, Test-AthenaAutoPatchLearning

Write-Host "ðŸ¤– Module Athena.AutoPatchLearning.psm1 chargÃ© (v1.2 Smart Threshold Build â€“ unifiÃ©)." -ForegroundColor Cyan




