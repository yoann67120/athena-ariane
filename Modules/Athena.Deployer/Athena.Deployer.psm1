# ====================================================================
# ðŸš€ Athena.Deployer.psm1 â€“ DÃ©ploiement & Ã‰volution PilotÃ©e
# Version : v1.0-Stable-OpAuth
# Description : DÃ©tecte les nouvelles phases, prÃ©pare le dÃ©ploiement,
#               crÃ©e les modules/scripts manquants et valide lâ€™intÃ©gritÃ©.
# Mode : OpÃ©rateur autorisÃ© (confirmation requise pour actions sensibles)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Initialisation des chemins ===
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$StructDir  = $RootDir
$DeployLog  = Join-Path $LogsDir  "AutoDeploy.log"
$ReportFile = Join-Path $LogsDir  "Deploy_Report.json"

foreach ($dir in @($LogsDir,$MemoryDir)) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# ====================================================================
# ðŸ§© Fonction : Write-AthenaDeployLog
# ====================================================================
function Write-AthenaDeployLog {
    param([string]$Message,[string]$Level="INFO")
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),$Level,$Message
    Add-Content -Path $DeployLog -Value $line
}

# ====================================================================
# ðŸ§© Fonction : Confirm-OperatorAction
# Demande lâ€™autorisation Ã  Yoann avant une action critique
# ====================================================================
function Confirm-OperatorAction {
    param([string]$Action)
    Write-Host ""
    Write-Host "ðŸ” Athena demande confirmation pour : $Action"
    $response = Read-Host "Souhaitez-vous valider cette action ? (O/N)"
    if ($response -match '^[OoYy]') {
        Write-AthenaDeployLog "Action autorisÃ©e par lâ€™opÃ©rateur : $Action" "AUTH"
        return $true
    } else {
        Write-AthenaDeployLog "Action refusÃ©e par lâ€™opÃ©rateur : $Action" "DENY"
        return $false
    }
}

# ====================================================================
# ðŸ§© Fonction : Get-NextPhaseInfo
# Lit /Memory/NextPhase.json pour identifier la prochaine phase
# ====================================================================
function Get-NextPhaseInfo {
    $NextFile = Join-Path $MemoryDir "NextPhase.json"
    if (!(Test-Path $NextFile)) { return $null }
    try { (Get-Content $NextFile -Raw) | ConvertFrom-Json } catch { $null }
}

# ====================================================================
# ðŸ§© Fonction : New-AthenaModuleSkeleton
# CrÃ©e un module PowerShell vide avec entÃªte standard
# ====================================================================
function New-AthenaModuleSkeleton {
    param([string]$ModuleName)
    $Target = Join-Path (Join-Path $RootDir "Modules") "$ModuleName.psm1"
    if ($Target -like "*-Fige.psm1") {
        Write-AthenaDeployLog "Tentative ignorÃ©e : module figÃ© $Target" "WARN"
        return
    }
    if (Test-Path $Target) {
        Write-AthenaDeployLog "Module existant : $ModuleName.psm1 â€“ IgnorÃ©" "INFO"
        return
    }

    if (Confirm-OperatorAction "crÃ©ation du module $ModuleName.psm1") {
        $Header = @"
# ====================================================================
# ðŸ§± $ModuleName.psm1 â€“ GÃ©nÃ©rÃ© automatiquement par Athena.Deployer
# Version : v0.1-Template
# ====================================================================
Set-StrictMode -Version Latest
`$ErrorActionPreference = "SilentlyContinue"

function Invoke-$($ModuleName) {
    Write-Output '$ModuleName prÃªt Ã  Ãªtre configurÃ©.'
}

Export-ModuleMember -Function Invoke-$($ModuleName)
"@
        $Header | Set-Content -Path $Target -Encoding UTF8
        Write-AthenaDeployLog "Module $ModuleName.psm1 crÃ©Ã©." "OK"
    }
}

# ====================================================================
# ðŸ§© Fonction : New-AthenaScriptSkeleton
# CrÃ©e le script associÃ© Ã  la phase
# ====================================================================
function New-AthenaScriptSkeleton {
    param([string]$ScriptName)
    $Target = Join-Path (Join-Path $RootDir "Scripts") "$ScriptName.ps1"
    if (Test-Path $Target) {
        Write-AthenaDeployLog "Script existant : $ScriptName.ps1 â€“ IgnorÃ©" "INFO"
        return
    }
    if (Confirm-OperatorAction "crÃ©ation du script $ScriptName.ps1") {
        $Content = @"
# ====================================================================
# âš™ï¸  $ScriptName.ps1 â€“ GÃ©nÃ©rÃ© automatiquement
# ====================================================================
param()
Write-Output 'ExÃ©cution du script $ScriptName.ps1...'
"@
        $Content | Set-Content -Path $Target -Encoding UTF8
        Write-AthenaDeployLog "Script $ScriptName.ps1 crÃ©Ã©." "OK"
    }
}

# ====================================================================
# ðŸ§  Fonction principale : Invoke-AthenaDeployer
# ====================================================================
function Invoke-AthenaDeployer {
    Write-AthenaDeployLog "----- DÃ‰BUT DU CYCLE DE DÃ‰PLOIEMENT -----"

    # Ã‰tape 1 : Analyse du contexte
    $NextPhase = Get-NextPhaseInfo
    if (-not $NextPhase) {
        Write-AthenaDeployLog "Aucune nouvelle phase dÃ©tectÃ©e." "INFO"
        return
    }

    $PhaseName = $NextPhase.phase
    Write-AthenaDeployLog "Nouvelle phase dÃ©tectÃ©e : $PhaseName" "INFO"

    # Ã‰tape 2 : Lecture du cahier des charges
    $StructFile = Join-Path $RootDir "ArianeV4_Structure_$PhaseName.txt"
    if (!(Test-Path $StructFile)) {
        Write-AthenaDeployLog "Fichier de structure introuvable pour $PhaseName" "ERROR"
        return
    }

    # Ã‰tape 3 : CrÃ©ation automatique
    $ModuleName = "Athena.$($PhaseName)"
    $ScriptName = "Athena_$($PhaseName)"
    New-AthenaModuleSkeleton -ModuleName $ModuleName
    New-AthenaScriptSkeleton -ScriptName $ScriptName

    # Ã‰tape 4 : Validation intÃ©gritÃ©
    if (Get-Command Invoke-AthenaIntegrity -ErrorAction SilentlyContinue) {
        Write-AthenaDeployLog "Validation dâ€™intÃ©gritÃ©..." "INFO"
        try {
            Invoke-AthenaIntegrity | Out-Null
            Write-AthenaDeployLog "IntÃ©gritÃ© vÃ©rifiÃ©e." "OK"
        } catch {
            Write-AthenaDeployLog "Erreur dâ€™intÃ©gritÃ© : $($_.Exception.Message)" "ERROR"
        }
    }

    # Ã‰tape 5 : Rapport JSON
    $Report = @{
        Timestamp = (Get-Date)
        Phase     = $PhaseName
        Status    = "OK"
    }
    $Report | ConvertTo-Json -Depth 3 | Set-Content $ReportFile -Encoding UTF8

    # Ã‰tape 6 : Notification cockpit (optionnelle)
    Write-AthenaDeployLog "ðŸ”´ Nouveau module dÃ©ployÃ© : $PhaseName" "OK"
    if (Get-Command Invoke-AthenaSpeak -ErrorAction SilentlyContinue) {
        Invoke-AthenaSpeak -Text "Nouveau module dÃ©ployÃ© $PhaseName."
    }

    Write-AthenaDeployLog "----- FIN DU CYCLE DE DÃ‰PLOIEMENT -----"
}
Export-ModuleMember -Function Invoke-AthenaDeployer



