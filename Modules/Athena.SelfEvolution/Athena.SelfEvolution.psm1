# ====================================================================
# â™»ï¸  Athena.SelfEvolution.psm1 â€“ v2.0 ExpansionCore
# ====================================================================
# Objectifs :
#   1. Scanner et comparer les modules Athena.*
#   2. GÃ©nÃ©rer rapports comparatifs (v1.1)
#   3. âš™ï¸  ExÃ©cuter le mode Auto-Expansion Core (Phase 37)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RootDir    = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ModulesDir = Join-Path $RootDir "Modules"
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"

foreach ($p in @($LogsDir, $MemoryDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

$LogFile  = Join-Path $LogsDir   "SelfEvolution.log"
$Report   = Join-Path $MemoryDir "SelfEvolutionReport.json"
$OldReport = "$Report.old"

# ====================================================================
# ðŸ”  Fonction principale â€“ comparaison
# ====================================================================
function Invoke-AthenaSelfEvolution {
    Write-Host "`nâ™»ï¸  DÃ©marrage du moteur Self-Evolution (Comparative Mode)..." -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value "`n=== Cycle lancÃ© $(Get-Date -Format u) ==="

    if (Test-Path $Report) {
        Copy-Item $Report $OldReport -Force
        Add-Content -Path $LogFile -Value "Ancien rapport sauvegardÃ© ($OldReport)"
    }

    $mods = Get-ChildItem -Path $ModulesDir -Filter "Athena.*.psm1" -ErrorAction SilentlyContinue
    if (-not $mods) { Write-Warning "âš ï¸ Aucun module trouvÃ©."; return }

    $liste = foreach ($m in $mods) {
        try {
            $hash = (Get-FileHash $m.FullName -Algorithm SHA256).Hash
            [PSCustomObject]@{
                Nom         = $m.Name
                Taille_Ko   = [math]::Round($m.Length / 1KB, 2)
                Modifie_Le  = $m.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                Hash_SHA256 = $hash
            }
        } catch { Write-Warning "Erreur lecture module $($m.Name): $_" }
    }

    $resume = [PSCustomObject]@{
        Date          = Get-Date
        TotalModules  = $liste.Count
        TailleMoyenne = [math]::Round(($liste.Taille_Ko | Measure-Object -Average).Average, 2)
        HashesUniques = ($liste.Hash_SHA256 | Select-Object -Unique).Count
    }

    $resultat = @{ RÃ©sumÃ© = $resume; Modules = $liste }
    $resultat | ConvertTo-Json -Depth 4 | Out-File $Report -Encoding utf8
    Add-Content -Path $LogFile -Value "âœ… Nouveau rapport gÃ©nÃ©rÃ© pour $($liste.Count) modules"

    # --- Comparaison simple ---
    if (Test-Path $OldReport) {
        try {
            $old = Get-Content $OldReport -Raw | ConvertFrom-Json
            $diffAjoutes = Compare-Object ($old.Modules.Nom) ($liste.Nom) -PassThru | Where-Object { $_ -in $liste.Nom }
            $diffSuppr   = Compare-Object ($old.Modules.Nom) ($liste.Nom) -PassThru | Where-Object { $_ -in $old.Modules.Nom }

            $diffModif = @()
            foreach ($new in $liste) {
                $ancien = $old.Modules | Where-Object { $_.Nom -eq $new.Nom }
                if ($ancien -and $ancien.Hash_SHA256 -ne $new.Hash_SHA256) { $diffModif += $new.Nom }
            }

            $comparatif = [PSCustomObject]@{
                Date              = Get-Date
                Modules_Ajoutes   = $diffAjoutes
                Modules_Supprimes = $diffSuppr
                Modules_Modifies  = $diffModif
                Total_Modifies    = ($diffAjoutes.Count + $diffSuppr.Count + $diffModif.Count)
            }

            $ComparatifFile = Join-Path $MemoryDir "SelfEvolutionDiff.json"
            $comparatif | ConvertTo-Json -Depth 4 | Out-File $ComparatifFile -Encoding utf8
            Add-Content -Path $LogFile -Value "ðŸ“ˆ DiffÃ©rences : AjoutÃ©s=$($diffAjoutes.Count) | SupprimÃ©s=$($diffSuppr.Count) | ModifiÃ©s=$($diffModif.Count)"
        } catch {
            Write-Warning "âš ï¸ Erreur comparaison : $_"
            Add-Content -Path $LogFile -Value "Erreur comparaison : $_"
        }
    }
    Write-Host "âœ… Self-Evolution comparative terminÃ©e." -ForegroundColor Green
}

# ====================================================================
# ðŸš€  Auto-Expansion Core â€“ Phase 37
# ====================================================================
function Invoke-AthenaExpansionCore {
    Write-Host "`nðŸš€  Lancement du moteur Auto-Expansion Core..." -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value "`n=== Phase 37 â€“ Auto-Expansion Core $(Get-Date -Format u) ==="

    $ExperimentalDir = Join-Path $ModulesDir "Experimental"
    if (!(Test-Path $ExperimentalDir)) { New-Item -ItemType Directory -Force -Path $ExperimentalDir | Out-Null }

    $modules = Get-ChildItem -Path $ModulesDir -Filter "Athena.*.psm1"
    $copied  = @()
    foreach ($m in $modules) {
        try {
            $target = Join-Path $ExperimentalDir $m.Name
            Copy-Item $m.FullName $target -Force
            $copied += $m.Name
        } catch { Write-Warning "Erreur copie $($m.Name): $_" }
    }

    $ExpansionReport = Join-Path $MemoryDir "ExpansionReport.json"
    $summary = [PSCustomObject]@{
        Date          = Get-Date
        Modules_Copies = $copied
        Total          = $copied.Count
        Status         = "Completed"
    }
    $summary | ConvertTo-Json -Depth 3 | Out-File $ExpansionReport -Encoding utf8
    Add-Content -Path $LogFile -Value "âœ… ExpansionCore terminÃ© â€“ $($copied.Count) modules copiÃ©s."
    Write-Host "âœ…  Auto-Expansion Core terminÃ©. Rapport : $ExpansionReport" -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-AthenaSelfEvolution, Invoke-AthenaExpansionCore
Write-Host "â™»ï¸  Module Athena.SelfEvolution.psm1 chargÃ© (v2.0-ExpansionCore)." -ForegroundColor Cyan


