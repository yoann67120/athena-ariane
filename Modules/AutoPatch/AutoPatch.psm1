# ====================================================================
# ðŸ”§ AutoPatch.psm1 â€“ RÃ©paration, Ã©volution & intÃ©gration GPT Architecte
# Version : v3.1-GPTFusion-AutoDetect
# ====================================================================
# NouveautÃ©s :
#   - IntÃ©gration automatique du code renvoyÃ© par GPT Architecte
#   - Surveillance du dernier message GPT (Logs\GPTArchitect.log)
#   - Application immÃ©diate via Apply-GPTCode
#   - Flag de contrÃ´le : $global:AutoPatchAutoDetect
#   - Journalisation et sauvegarde avant import
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$ModulesDir = Join-Path $RootDir "Modules"
$LogsDir    = Join-Path $RootDir "Logs"
$ArchiveDir = Join-Path $RootDir "Archive"
$MemoryDir  = Join-Path $RootDir "Memory"
$GPTLog     = Join-Path $LogsDir "GPTArchitect.log"
$LogFile    = Join-Path $LogsDir "AutoPatch.log"

foreach ($dir in @($LogsDir,$ArchiveDir,$MemoryDir)) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

if (-not (Get-Variable -Name "global:AutoPatchInProgress" -ErrorAction SilentlyContinue)) {
    $global:AutoPatchInProgress = $false
}
if (-not (Get-Variable -Name "global:AutoPatchAutoDetect" -ErrorAction SilentlyContinue)) {
    $global:AutoPatchAutoDetect = $true
}

function Write-AutoPatchLog {
    param([string]$Msg,[string]$L="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$L] $Msg"
}

# ====================================================================
# ðŸ”— Application directe dâ€™un code renvoyÃ© par GPT Architecte
# ====================================================================
function Apply-GPTCode {
    param([string]$Code,[string]$SuggestedName="GPT_Module.psm1")

    if (-not $Code) { Write-Host "âš ï¸ Aucun code reÃ§u du GPT Architecte."; return }

    $safeName = ($SuggestedName -replace '[^a-zA-Z0-9_.-]', '_')
    $TargetPath = Join-Path $ModulesDir $safeName
    $BackupPath = "$TargetPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

    try {
        if (Test-Path $TargetPath) {
            Copy-Item $TargetPath $BackupPath -Force
            Write-AutoPatchLog "Sauvegarde existante : $BackupPath"
        }

        # Sandbox : vÃ©rifie que le code semble PowerShell
        if ($Code -notmatch "function|Set-StrictMode|Export-ModuleMember") {
            Write-Warning "âŒ Le contenu reÃ§u nâ€™est pas du code PowerShell identifiable."
            Write-AutoPatchLog "Rejet du code non conforme (aucune fonction dÃ©tectÃ©e)" "WARN"
            return
        }

        $Code | Out-File $TargetPath -Encoding UTF8
        Write-AutoPatchLog "Code GPT Ã©crit : $TargetPath"
        try {
            Import-Module $TargetPath -Force -Global
            Write-Host "âœ… Module GPT appliquÃ© et chargÃ© : $safeName" -ForegroundColor Green
            Write-AutoPatchLog "Module $safeName importÃ© avec succÃ¨s."
        } catch {
            Write-Warning "âš ï¸ Ã‰chec import module GPT : $_"
            Write-AutoPatchLog "Erreur import module GPT : $($_.Exception.Message)" "ERROR"
        }
    } catch {
        Write-Warning "âš ï¸ Erreur durant lâ€™application GPT : $_"
        Write-AutoPatchLog "Erreur Apply-GPTCode : $($_.Exception.Message)" "ERROR"
    }
}

# ====================================================================
# ðŸ‘ï¸ DÃ©tection automatique de code GPT
# ====================================================================
function Watch-GPTAutoPatch {
    if (-not $global:AutoPatchAutoDetect) { return }
    if (!(Test-Path $GPTLog)) { return }

    try {
        $lastLine = Get-Content $GPTLog -Tail 40 | Out-String
        if ($lastLine -match "#\s*={3,}.*?psm1") {
            Write-Host "`nðŸ” DÃ©tection dâ€™un module PowerShell dans GPTArchitect.log..." -ForegroundColor Cyan
           $moduleName = if ($lastLine -match '([\w\.\-]+\.psm1)') { $matches[1] } else { 'GPT_Module.psm1' }

            Apply-GPTCode -Code $lastLine -SuggestedName $moduleName
            Write-AutoPatchLog "DÃ©tection automatique GPT â†’ module $moduleName appliquÃ©."
        }
    } catch {
        Write-AutoPatchLog "Erreur Watch-GPTAutoPatch : $($_.Exception.Message)" "ERROR"
    }
}

# ====================================================================
# ðŸ©º RÃ©paration principale
# ====================================================================
function Invoke-AutoPatch {

    if ($global:AutoPatchInProgress) {
        Write-Host "â³ AutoPatch dÃ©jÃ  en cours â€“ sortie immÃ©diate." -ForegroundColor Yellow
        Write-AutoPatchLog "AutoPatch ignorÃ© (dÃ©jÃ  en cours)."
        return
    }
    $global:AutoPatchInProgress = $true
    Write-Host "`nðŸ”§ DÃ©marrage du processus AutoPatch..." -ForegroundColor Cyan
    Write-AutoPatchLog "DÃ©marrage AutoPatch..."

    if (Test-Path $RootDir) { Write-Host "âœ… Structure Ariane vÃ©rifiÃ©e." }

    # --- Application du plan GPT sâ€™il existe ---
    $PlanFile = Join-Path $RootDir "Data\\GPT\\Recommandations.json"
    if (Test-Path $PlanFile) {
        Write-Host "ðŸ§© Application du plan de reconstruction..." -ForegroundColor Green
        try {
            $Plan = Get-Content $PlanFile -Raw | ConvertFrom-Json
            foreach ($action in $Plan.recommandations) {
                if ($null -eq $action) { continue }
                if ($action.action -eq "New-LocalFile") {
                    $TargetPath = Join-Path $RootDir $action.path
                    $Dir = Split-Path $TargetPath -Parent
                    if (!(Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir -Force | Out-Null }
                    Set-Content -Path $TargetPath -Value $action.content -Encoding UTF8
                    Write-Host "ðŸ“„ CrÃ©Ã© : $($action.path)" -ForegroundColor White
                    Write-AutoPatchLog "CrÃ©Ã© : $($action.path)"
                }
            }
        } catch {
            Write-Warning ("âš ï¸ Erreur lecture plan : " + ($_.Exception.Message))
            Write-AutoPatchLog "Erreur plan reconstruction : $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Host "âš™ï¸ Aucun plan de reconstruction dÃ©tectÃ© (mode standard)."
    }

    # ðŸš€ VÃ©rification du lanceur principal
    $LauncherPath = Join-Path $RootDir "Start-Ariane.ps1"
    if (!(Test-Path $LauncherPath)) {
@"
# ====================================================================
# ðŸš€ Start-Ariane.ps1 â€“ GÃ©nÃ©rÃ© automatiquement
# ====================================================================
Write-Host "`nðŸš€ Lancement du systÃ¨me Ariane V4..." -ForegroundColor Cyan
Set-Location (Split-Path -Parent \$MyInvocation.MyCommand.Path)
try {
    Import-Module .\Modules\Athena.Engine.psm1 -Force -Global
    Write-Host "`nðŸŒ™ Ariane est prÃªte Ã  interagir." -ForegroundColor Cyan
}
catch {
    Write-Warning "âš ï¸ Erreur au lancement d'Athena.Engine : \$_"
}
"@ | Set-Content -Path $LauncherPath -Encoding UTF8
        Write-Host "âœ… Lanceur rÃ©gÃ©nÃ©rÃ© automatiquement : $LauncherPath" -ForegroundColor Green
        Write-AutoPatchLog "Lanceur rÃ©gÃ©nÃ©rÃ© automatiquement."
    } else {
        Write-Host "âœ… Lanceur Ariane dÃ©jÃ  prÃ©sent." -ForegroundColor Green
    }

    # ðŸ§  Ã‰tape finale â€“ IntelliFix contextuel
    $IntelliFixPath = Join-Path $ModulesDir "AutoPatch.IntelliFix.psm1"
    if (Test-Path $IntelliFixPath) {
        try {
            Import-Module $IntelliFixPath -Force -Global -ErrorAction SilentlyContinue | Out-Null
            Write-Host "`nðŸ§  Analyse contextuelle post-patch (IntelliFix)..." -ForegroundColor Cyan
            Invoke-AutoPatchIntelliFix -TargetDir $ModulesDir
        } catch {
            Write-Warning "âš ï¸ Erreur lors de lâ€™analyse contextuelle : $_"
            Write-AutoPatchLog "Erreur IntelliFix : $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Host "âš™ï¸ IntelliFix non trouvÃ© â€“ Ã©tape ignorÃ©e."
    }

    # ðŸª¶ VÃ©rifie le dernier code GPT reÃ§u
    Watch-GPTAutoPatch

    Write-Host "`nâœ… AutoPatch terminÃ©." -ForegroundColor Green
    Write-AutoPatchLog "AutoPatch terminÃ©."
    $global:AutoPatchInProgress = $false
}

# ====================================================================
# ðŸ§¬ AutoEvolution (inchangÃ©e)
# ====================================================================
function Invoke-AutoEvolution {
    Write-Host "`nðŸ§¬ DÃ©tection des opportunitÃ©s dâ€™Ã©volution..." -ForegroundColor Cyan
    Write-AutoPatchLog "DÃ©marrage AutoEvolution..."

    $LearningFile = Join-Path $MemoryDir "SelfLearning.json"
    if (!(Test-Path $LearningFile)) {
        Write-Host "âš ï¸ Aucun fichier dâ€™apprentissage dÃ©tectÃ©."
        return
    }

    try {
        $Learning = Get-Content $LearningFile -Raw | ConvertFrom-Json
        $ideas = $Learning.Insights
        if (-not $ideas -or $ideas.Count -eq 0) {
            Write-Host "âœ… Aucun besoin dâ€™Ã©volution dÃ©tectÃ©."
            return
        }

        foreach ($idea in $ideas) {
            $cleanName = ($idea -replace '[^a-zA-Z0-9]', '')
            if (-not $cleanName) { continue }
            $targetPath = Join-Path $ModulesDir "$cleanName.psm1"
            $core = "Write-Host 'ðŸ§© Module expÃ©rimental actif (idÃ©e : $idea)'"
            $content = "# Module expÃ©rimental gÃ©nÃ©rÃ© automatiquement â€“ idÃ©e : $idea`n$core"
            Set-Content -Path $targetPath -Value $content -Encoding UTF8
            Write-AutoPatchLog "CrÃ©ation/mÃ j module expÃ©rimental : $cleanName"
        }

        Write-Host "âœ… AutoEvolution terminÃ©e."
        Write-AutoPatchLog "AutoEvolution terminÃ©e."
    } catch {
        Write-Warning ("âš ï¸ Erreur durant AutoEvolution : " + ($_.Exception.Message))
        Write-AutoPatchLog "Erreur AutoEvolution : $($_.Exception.Message)" "ERROR"
    }
}

Export-ModuleMember -Function Invoke-AutoPatch, Invoke-AutoEvolution, Apply-GPTCode, Watch-GPTAutoPatch
Write-Host "âœ… Module AutoPatch v3.1-GPTFusion-AutoDetect chargÃ© (intÃ©gration GPT + sandbox + auto-dÃ©tection)." -ForegroundColor Cyan




