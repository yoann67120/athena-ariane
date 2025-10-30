# ====================================================================
# ðŸ¤– Athena.Engine.psm1 â€“ Cerveau autonome dâ€™Ariane V4
# Cycle : Observation â†’ RÃ©flexion â†’ Action â†’ Rapport â†’ AutoLearning â†’ AutoEvolution
# Version : v3.8-Stable-Fix (AutoRepair + JSON-Fix + ModuleCheck)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Dossiers principaux
Import-Module (Join-Path $ModulesDir 'ActionEngine.psm1') -Force -Global | Out-Null ======================================================
$ModuleDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleDir
$LogsDir     = Join-Path $RootDir "Logs"
$MemoryDir   = Join-Path $RootDir "Memory"
$DataDir     = Join-Path $RootDir "Data\GPT"
$ModulesDir  = Join-Path $RootDir "Modules"
$ReportLog   = Join-Path $LogsDir "AthenaReport.log"
$RecoFile    = Join-Path $DataDir "Recommandations.json"

foreach ($p in @($LogsDir,$MemoryDir,$DataDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Write-AthenaLog {
    param([string]$Msg,[string]$L="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $ReportLog -Value "[$t][$L] $Msg"
}

# ====================================================================
# ðŸ©º VÃ©rification et auto-rÃ©paration de base
# ====================================================================
Import-Module (Join-Path $ModulesDir "AutoPatch.psm1") -Force -Global -ErrorAction SilentlyContinue | Out-Null
if (-not (Get-Command Invoke-AutoPatch -ErrorAction SilentlyContinue)) {
    $autoPatchPath = Join-Path $ModulesDir "AutoPatch.psm1"
    if (Test-Path $autoPatchPath) {
        Import-Module $autoPatchPath -Force -Global | Out-Null
        Write-Host "ðŸ”§ AutoPatch initialisÃ© (vÃ©rification prÃ©coce)." -ForegroundColor DarkCyan
    } else {
        Write-Warning "âš ï¸ AutoPatch.psm1 introuvable â€“ crÃ©ation manuelle nÃ©cessaire."
    }
}

# ====================================================================
# ðŸ”§ Initialisation IA locale (LocalModel)
# ====================================================================
try {
    Import-Module (Join-Path $ModulesDir "LocalModel.psm1") -Force -Global | Out-Null
    if (Get-Command Invoke-LocalModel -ErrorAction SilentlyContinue) {
        Write-Host "ðŸ§  LocalModel chargÃ© et fonction Invoke-LocalModel disponible." -ForegroundColor Green
    } else {
        Write-Warning "âš ï¸ Fonction Invoke-LocalModel introuvable â€“ exÃ©cution AutoPatch..."
        Invoke-AutoPatch
    }
}
catch {
    Write-Warning "âš ï¸ Erreur lors du chargement de LocalModel : $($_.Exception.Message)"
    Invoke-AutoPatch
}

# ====================================================================
# ðŸ’¬ Initialisation du module Persona
# ====================================================================
try {
    Import-Module (Join-Path $ModulesDir "Athena.Persona.psm1") -Force -Global -ErrorAction SilentlyContinue | Out-Null
    if (Get-Command Invoke-AthenaPersona -ErrorAction SilentlyContinue) {
        Write-Host "ðŸ’¬ Athena.Persona.psm1 chargÃ© (adaptation du ton activÃ©e)." -ForegroundColor Green
    } else {
        Write-Warning "âš ï¸ Fonction Invoke-AthenaPersona introuvable â€“ tentative de rÃ©paration..."
        Invoke-AutoPatch
    }
}
catch {
    Write-Warning "âš ï¸ Erreur lors du chargement d'Athena.Persona : $($_.Exception.Message)"
    Invoke-AutoPatch
}

# ====================================================================
# ðŸš€ VÃ©rification du lanceur principal
# ====================================================================
$LauncherPath = Join-Path $RootDir "Start-Ariane.ps1"
if (!(Test-Path $LauncherPath)) {
    Write-Host "ðŸ› ï¸ Lanceur Ariane absent â€“ rÃ©gÃ©nÃ©ration via AutoPatch..." -ForegroundColor Yellow
    Invoke-AutoPatch
} else {
    Write-Host "âœ… Lanceur Ariane prÃ©sent." -ForegroundColor Green
}

# ====================================================================
# 1ï¸âƒ£ Observation â€“ Ã©tat local
# ====================================================================
function Invoke-AthenaObservation {
    $essential = @("AutoPatch.psm1","LocalModel.psm1","ActionEngine.psm1","Athena.Persona.psm1")
    foreach ($m in $essential) {
        $path = Join-Path $ModulesDir $m
        if (Test-Path $path) { Import-Module $path -Force -Global -ErrorAction SilentlyContinue | Out-Null }
    }

    Write-Host "`nðŸ”­ Observation du systÃ¨me..." -ForegroundColor Yellow
    $modules = @(Get-ChildItem $ModulesDir -Filter *.psm1 | Select-Object -ExpandProperty Name)
    $count   = if ($modules) { $modules.Count } else { 0 }

    $state = [PSCustomObject]@{
        Date        = Get-Date
        ModuleCount = $count
        Modules     = $modules
        MemoryUsage = [math]::Round((Get-Process -Id $PID).PM/1MB,2)
    }
    Write-AthenaLog "Observation terminÃ©e : $($state | ConvertTo-Json -Compress)"
    return $state
}

# ====================================================================
# 2ï¸âƒ£ RÃ©flexion â€“ gÃ©nÃ©ration du plan via IA
# ====================================================================
function Invoke-AthenaReflection {
    Write-Host "`nðŸ§  RÃ©flexion en cours..." -ForegroundColor Cyan
    if (-not (Get-Command Invoke-LocalModel -ErrorAction SilentlyContinue)) {
        Write-Warning "âš ï¸ LocalModel absent â€“ tentative de recharge..."
        Import-Module (Join-Path $ModulesDir "LocalModel.psm1") -Force -Global | Out-Null
    }

    $Prompt = "Analyse lâ€™Ã©tat suivant et propose un plan dâ€™action JSON : $(Invoke-AthenaObservation | ConvertTo-Json -Compress)"
    if (Get-Command Invoke-AthenaPersona -ErrorAction SilentlyContinue) {
        $Prompt = Invoke-AthenaPersona -Prompt $Prompt
    }

    try {
        $Response = Invoke-LocalModel -Prompt $Prompt
        if ($Response) {
            if ($Response -match "{") {
                $jsonPart = $Response.Substring($Response.IndexOf("{"))
                try {
                    $null = $jsonPart | ConvertFrom-Json -ErrorAction Stop
                    $jsonPart | Set-Content -Path $RecoFile -Encoding UTF8
                    Write-Host "ðŸ“ Plan sauvegardÃ© : $RecoFile" -ForegroundColor Green
                } catch {
                    Write-Warning "âš ï¸ RÃ©ponse IA non valide JSON, sauvegarde brute."
                    $Response | Set-Content -Path $RecoFile -Encoding UTF8
                }
            } else {
                $Response | Set-Content -Path $RecoFile -Encoding UTF8
            }
            Write-AthenaLog "RÃ©flexion terminÃ©e : plan gÃ©nÃ©rÃ©."
        } else {
            Write-Warning "âš ï¸ Aucune rÃ©ponse IA â€“ plan non gÃ©nÃ©rÃ©."
        }
    }
    catch {
        Write-Warning "âš ï¸ Erreur IA pendant la rÃ©flexion : $_"
    }
}

# ====================================================================
# 3ï¸âƒ£ Action â€“ exÃ©cution du plan
# ====================================================================
function Invoke-AthenaAction {
    Write-Host "`nâš™ï¸ Application du plan..." -ForegroundColor Magenta
    $ActionPath = Join-Path $ModulesDir "ActionEngine.psm1"
    if (!(Test-Path $ActionPath)) {
        Write-Warning "âš ï¸ ActionEngine manquant â€“ appel AutoPatch..."
        Invoke-AutoPatch
    }
    Import-Module $ActionPath -Force -Global -ErrorAction SilentlyContinue | Out-Null
    if (Test-Path $RecoFile) {
        try { Invoke-ActionPlan -Plan $RecoFile } catch { Write-Warning "âš ï¸ Erreur pendant l'application du plan : $_" }
    } else {
        Write-Warning "âš ï¸ Aucun plan trouvÃ© : $RecoFile"
    }
}

# ====================================================================
# 4ï¸âƒ£ Rapport â€“ synthÃ¨se du cycle
# ====================================================================
function Invoke-AthenaReport {
    Write-Host "`nðŸ“Š Rapport du cycle..." -ForegroundColor Green
    $modules = Get-ChildItem $ModulesDir -Filter *.psm1 -ErrorAction SilentlyContinue
    $count = if ($modules) { $modules.Count } else { 0 }

    $Summary = [PSCustomObject]@{
        Date     = Get-Date
        Modules  = $count
        Logs     = (Get-ChildItem $LogsDir -Filter *.log -ErrorAction SilentlyContinue).Count
    }
    $Path = Join-Path $MemoryDir "DailySummary.json"
    $Summary | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Encoding UTF8
    Write-Host "âœ… Rapport gÃ©nÃ©rÃ© : $Path"
}

# ====================================================================
# 5ï¸âƒ£ Auto-Learning
# ====================================================================
function Invoke-AthenaLearning {
    Write-Host "`nðŸ§  Phase d'apprentissage automatique..." -ForegroundColor Cyan
    $AutoLearnPath = Join-Path $ModulesDir "Athena.AutoLearning.psm1"
    if (Test-Path $AutoLearnPath) {
        Import-Module $AutoLearnPath -Force -Global -ErrorAction SilentlyContinue | Out-Null
        if (Get-Command Invoke-AthenaAutoLearning -ErrorAction SilentlyContinue) {
            Invoke-AthenaAutoLearning
        }
    }
}

# ====================================================================
# ðŸ—£ï¸ Dialogue direct
# ====================================================================
function Invoke-AthenaDialogue {
    param([string]$Prompt)
    Write-Host "`nðŸ—£ï¸ Dialogue direct avec Athena..." -ForegroundColor Yellow
    try {
        if (Get-Command Invoke-AthenaPersona -ErrorAction SilentlyContinue) {
            $Prompt = Invoke-AthenaPersona -Prompt $Prompt
        }
        $Response = Invoke-LocalModel -Prompt $Prompt
        Write-Host "`nðŸ’¬ RÃ©ponse d'Athena :" -ForegroundColor Cyan
        Write-Host $Response -ForegroundColor White
        return $Response
    }
    catch {
        Write-Warning "âš ï¸ Erreur pendant le dialogue : $_"
    }
}

# ====================================================================
# 6ï¸âƒ£ Cycle complet
# ====================================================================
function Invoke-AthenaCycle {
    Write-Host "`nðŸš€ Lancement du cycle Athena autonome..." -ForegroundColor Cyan
    try {
        Invoke-AthenaObservation | Out-Null
        Invoke-AthenaReflection
        Invoke-AthenaAction
        Invoke-AthenaReport
        Invoke-AthenaLearning
        Write-Host "`nðŸŒ™ Cycle Athena terminÃ©." -ForegroundColor Cyan
    }
    catch {
        Write-Warning "âš ï¸ Erreur inattendue : $_"
        Invoke-AutoPatch
    }
}

# ====================================================================
# ðŸ“¤ Export global
# ====================================================================
Export-ModuleMember -Function `
    Invoke-AthenaCycle, Invoke-AthenaObservation, Invoke-AthenaReflection,
    Invoke-AthenaAction, Invoke-AthenaReport, Invoke-AthenaLearning,
    Invoke-AthenaDialogue -ErrorAction SilentlyContinue

Set-Alias -Name Invoke-Athena -Value Invoke-AthenaCycle -Force
Export-ModuleMember -Alias Invoke-Athena -Function Invoke-AthenaCycle -Force

Write-Host "âœ… Athena.Engine.psm1 v3.8-Stable-Fix chargÃ© (JSON-Fix + ModuleCheck + Count-Fix)." -ForegroundColor Cyan





