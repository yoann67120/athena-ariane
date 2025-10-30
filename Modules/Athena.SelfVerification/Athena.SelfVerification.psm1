# ====================================================================
# ðŸ§© Athena.SelfVerification.psm1 â€“ v1.5 StableCycle
# Objectif :
#   - VÃ©rifier lâ€™intÃ©gritÃ© complÃ¨te dâ€™Athena
#   - ContrÃ´ler la cohÃ©rence des modules, logs et JSON
#   - Produire un rapport clair et sauvegardÃ© automatiquement
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- DÃ©tection dynamique des dossiers ---
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$ModulesDir = Join-Path $RootDir "Modules"
$MemoryDir  = Join-Path $RootDir "Memory"

# --- Fichiers de sortie ---
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$ReportFile = Join-Path $LogsDir "AthenaVerification.log"

# ====================================================================
# âœï¸ Fonction de log
# ====================================================================
function Write-VerificationLog {
    param([string]$Msg)
    $t = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $ReportFile -Value "[$t] $Msg"
}

# ====================================================================
# ðŸ” Fonction principale
# ====================================================================
function Invoke-AthenaSelfVerification {
    Write-Host "`nðŸ§  Lancement du moteur de vÃ©rification complÃ¨te dâ€™Athena..." -ForegroundColor Cyan
    Write-VerificationLog "=== Cycle de vÃ©rification complet dÃ©marrÃ© ==="

    $results = @()
    $modules = Get-ChildItem -Path $ModulesDir -Filter "*.psm1" -ErrorAction SilentlyContinue

    foreach ($m in $modules) {
        try {
            $hash = (Get-FileHash $m.FullName -Algorithm SHA256).Hash.Substring(0, 8)
            $size = [math]::Round($m.Length / 1KB, 2)
            $status = if ($size -gt 0) { "âœ… IntÃ¨gre" } else { "âŒ Vide" }

            $results += [PSCustomObject]@{
                Module = $m.Name
                Taille = "$size Ko"
                Hash   = $hash
                Statut = $status
            }

            if ($status -eq "âŒ Vide") {
                Write-VerificationLog "âš ï¸ Module vide : $($m.Name)"
            }
        } catch {
            Write-VerificationLog "âŒ Erreur de lecture : $($m.Name)"
        }
    }

    # --- VÃ©rification des fichiers JSON principaux ---
    $jsonFiles = @("LearningRules.json", "LearningSummary.json", "HarmonyState.json")
    foreach ($f in $jsonFiles) {
        $path = Join-Path $MemoryDir $f
        if (Test-Path $path) {
            try {
                Get-Content $path -Raw | ConvertFrom-Json | Out-Null
                Write-VerificationLog "âœ… JSON valide : $f"
            } catch {
                Write-VerificationLog "âš ï¸ JSON corrompu : $f"
            }
        } else {
            Write-VerificationLog "âŒ JSON manquant : $f"
        }
    }

    # --- Calcul du score global ---
    $ok = ($results | Where-Object { $_.Statut -eq "âœ… IntÃ¨gre" }).Count
    $total = $results.Count
    $score = if ($total -gt 0) { [math]::Round(($ok / $total) * 100, 1) } else { 0 }

    Write-Host "`nðŸ“„ Score global dâ€™intÃ©gritÃ© : $score%" -ForegroundColor Green
    Write-VerificationLog "ðŸ“„ Score global dâ€™intÃ©gritÃ© : $score%"

    if ($score -ge 90) {
        Write-Host "ðŸ§  Athena est totalement stable." -ForegroundColor Green
        Write-VerificationLog "âœ… SystÃ¨me stable"
    } elseif ($score -ge 70) {
        Write-Host "âš™ï¸ Athena est partiellement stable â€“ vÃ©rification recommandÃ©e." -ForegroundColor Yellow
        Write-VerificationLog "âš™ï¸ SystÃ¨me partiellement stable"
    } else {
        Write-Host "ðŸš¨ Athena instable â€“ exÃ©cution dâ€™AutoPatch recommandÃ©e." -ForegroundColor Red
        Write-VerificationLog "ðŸš¨ SystÃ¨me instable"
    }

    Write-Host "`nðŸ—‚ï¸ Rapport sauvegardÃ© : $ReportFile" -ForegroundColor Gray
    Write-VerificationLog "Rapport sauvegardÃ© : $ReportFile"
    Write-Host ""
}

# ====================================================================
# ðŸ”š Export
# ====================================================================
Export-ModuleMember -Function Invoke-AthenaSelfVerification
Write-Host "âœ… Module Athena.SelfVerification.psm1 chargÃ© (v1.5-StableCycle)." -ForegroundColor Cyan


