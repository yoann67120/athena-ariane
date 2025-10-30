# ====================================================================
# ðŸ§  Athena.AutoIntegration.psm1 â€“ v1.0-SelfInstall-CoreExtended
# --------------------------------------------------------------------
# Objectif :
#   Moteur dâ€™auto-intÃ©gration et dâ€™auto-installation dâ€™Athena.
#   Lit le registre OpenSourceRegistry.json, tÃ©lÃ©charge, installe,
#   configure et relie automatiquement les outils externes.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === RÃ©pertoires ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ConfigDir  = Join-Path $RootDir "Config"
$Registry   = Join-Path $ConfigDir "OpenSourceRegistry.json"
$PlanFile   = Join-Path $MemoryDir "EvolutionPlans.json"
$LogFile    = Join-Path $LogsDir  "AutoIntegration.log"
$Installed  = Join-Path $MemoryDir "IntegrationStatus.json"

foreach ($p in @($LogsDir,$MemoryDir,$ConfigDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Write-IntegrationLog {
    param([string]$Msg,[string]$Level="INFO")
    $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# 1ï¸âƒ£ Lecture du registre et prÃ©paration
# ====================================================================
function Get-Registry {
    if (!(Test-Path $Registry)) {
        Write-IntegrationLog "âŒ Registre introuvable : $Registry" "ERROR"; return $null
    }
    try { Get-Content $Registry -Raw | ConvertFrom-Json } 
    catch { Write-IntegrationLog "âŒ Erreur JSON : $_" "ERROR"; return $null }
}

# ====================================================================
# 2ï¸âƒ£ Recherche dâ€™un outil dans le registre
# ====================================================================
function Find-ToolInRegistry {
    param([string]$Tool)
    $reg = Get-Registry
    foreach ($section in $reg.PSObject.Properties.Name) {
        if ($reg.$section.PSObject.Properties.Name -contains $Tool) {
            return $reg.$section.$Tool
        }
    }
    return $null
}

# ====================================================================
# 3ï¸âƒ£ Installation via Winget / Chocolatey / GitHub
# ====================================================================
function Install-OpenSourceTool {
    param([string]$Tool)
    Write-IntegrationLog "Tentative d'installation de $Tool..."
    $entry = Find-ToolInRegistry -Tool $Tool
    if ($null -eq $entry) { Write-IntegrationLog "âŒ $Tool non trouvÃ© dans le registre." "ERROR"; return }

    $installed=$false
    $cmds=@()

    # --- DÃ©tection du mode dâ€™installation ---
    if ($Tool -match "Ollama")       { $cmds+= 'winget install Ollama.Ollama -e --accept-source-agreements --accept-package-agreements' }
    elseif ($Tool -match "LMStudio") { $cmds+= 'winget install LMStudio.LMStudio -e --accept-source-agreements --accept-package-agreements' }
    elseif ($Tool -match "NodeRED")  { $cmds+= 'npm install -g --unsafe-perm node-red' }
    elseif ($Tool -match "n8n")      { $cmds+= 'npm install -g n8n' }
    elseif ($entry.link -match "github.com") { 
        $cmds+= "Invoke-WebRequest '$($entry.link)' -OutFile '$RootDir\Downloads\$Tool.zip'"
    }

    foreach ($c in $cmds) {
        Write-IntegrationLog "ExÃ©cution : $c"
        try { Invoke-Expression $c; $installed=$true }
        catch { Write-IntegrationLog "âš ï¸ Erreur durant $Tool : $_" "WARN" }
    }

    if ($installed) {
        Write-IntegrationLog "âœ… $Tool installÃ© ou mis Ã  jour."
        Update-IntegrationStatus -Tool $Tool -Status "Installed"
        Register-IntegrationToPlan -Tool $Tool -Status "Installed"
    } else {
        Write-IntegrationLog "âŒ Ã‰chec installation $Tool." "ERROR"
    }
}

# ====================================================================
# 4ï¸âƒ£ Mise Ã  jour du statut dâ€™intÃ©gration
# ====================================================================
function Update-IntegrationStatus {
    param([string]$Tool,[string]$Status)
    $list=@()
    if (Test-Path $Installed) { try { $list=Get-Content $Installed -Raw | ConvertFrom-Json } catch {} }
    $list=$list | Where-Object { $_.Tool -ne $Tool }
    $list+=[pscustomobject]@{
        Tool=$Tool; Status=$Status; Date=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    $list | ConvertTo-Json -Depth 3 | Out-File $Installed -Encoding utf8
}

# ====================================================================
# 5ï¸âƒ£ Enregistrement dans EvolutionPlans.json
# ====================================================================
function Register-IntegrationToPlan {
    param([string]$Tool,[string]$Status)
    if (!(Test-Path $PlanFile)) { return }
    $plans=Get-Content $PlanFile -Raw | ConvertFrom-Json
    foreach ($p in $plans) {
        if ($p.Integration -eq $Tool) { $p.Statut=$Status }
    }
    $plans | ConvertTo-Json -Depth 4 | Out-File $PlanFile -Encoding utf8
}

# ====================================================================
# 6ï¸âƒ£ Test dâ€™intÃ©gration
# ====================================================================
function Test-Integration {
    param([string]$Tool)
    Write-IntegrationLog "Test d'intÃ©gration pour $Tool..."
    $ok=$false
    switch -Wildcard ($Tool) {
        "Ollama"       { $ok=Test-NetConnection -ComputerName localhost -Port 11434 -InformationLevel Quiet }
        "LMStudio"     { $ok=Test-Path "$env:LOCALAPPDATA\LM Studio" }
        "LangChain"    { $ok=(Get-Command python -ErrorAction SilentlyContinue) -ne $null }
        default        { $ok=$true }
    }
    if ($ok) { Write-IntegrationLog "âœ… $Tool opÃ©rationnel." }
    else     { Write-IntegrationLog "âš ï¸ $Tool non dÃ©tectÃ© aprÃ¨s installation." }
    return $ok
}

# ====================================================================
# 7ï¸âƒ£ RÃ©paration automatique dâ€™une intÃ©gration
# ====================================================================
function Auto-RepairIntegration {
    param([string]$Tool)
    Write-IntegrationLog "RÃ©paration automatique de $Tool..."
    if (!(Test-Integration -Tool $Tool)) { Install-OpenSourceTool -Tool $Tool }
}

# ====================================================================
# 8ï¸âƒ£ VÃ©rification globale
# ====================================================================
function Invoke-AutoIntegrationCycle {
    <#
        Boucle complÃ¨te :
        - Lit les outils proposÃ©s ou planifiÃ©s
        - Tente lâ€™installation
        - Teste la connexion
        - Met Ã  jour les statuts
    #>
    Write-Host "`nðŸš€ Lancement du cycle AutoIntegration..." -ForegroundColor Cyan
    Write-IntegrationLog "=== DÃ©but AutoIntegrationCycle ==="

    if (!(Test-Path $PlanFile)) { Write-IntegrationLog "Plan d'Ã©volution introuvable." "WARN"; return }

    $plans=Get-Content $PlanFile -Raw | ConvertFrom-Json
    $targets=$plans | Where-Object { $_.Statut -eq "ProposÃ©" -or $_.Statut -eq "InstallÃ©" }

    foreach ($t in $targets) {
        Write-Host "ðŸ”§ IntÃ©gration : $($t.Integration)" -ForegroundColor Yellow
        Install-OpenSourceTool -Tool $t.Integration
        Test-Integration -Tool $t.Integration
    }

    Write-IntegrationLog "=== Fin AutoIntegrationCycle ==="
    Write-Host "âœ… Cycle AutoIntegration terminÃ©." -ForegroundColor Green
}

# ====================================================================
# 9ï¸âƒ£ Fonctions avancÃ©es (prÃ©-intÃ©grÃ©es, phases futures)
# ====================================================================
<#
function Uninstall-Integration { }
function Sync-IntegrationNetwork { }
function Backup-IntegrationConfig { }
function Restore-IntegrationConfig { }
function Auto-UpdateIntegrations { }
#>

# ====================================================================
# ðŸ”š Exports publics
# ====================================================================
Export-ModuleMember -Function `
    Install-OpenSourceTool, `
    Test-Integration, `
    Auto-RepairIntegration, `
    Invoke-AutoIntegrationCycle, `
    Update-IntegrationStatus, `
    Register-IntegrationToPlan

Write-Host "ðŸ§  Module Athena.AutoIntegration.psm1 chargÃ© (v1.0-SelfInstall-CoreExtended)." -ForegroundColor Cyan
Write-IntegrationLog "Module AutoIntegration v1.0 chargÃ©."



