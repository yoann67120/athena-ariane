# ====================================================================
# ðŸ§  Athena.Maintainer.psm1 â€“ Auto-Maintenance Adaptative & Validation Continue
# Version : v1.0-Stable
# Description : VÃ©rifie, rÃ©pare et valide les modules aprÃ¨s chaque dÃ©ploiement.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Chemins de base ===
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ReportFile = Join-Path $LogsDir "Maintain_Report.json"
$LogFile    = Join-Path $LogsDir "AutoMaintain.log"

foreach ($d in @($LogsDir,$MemoryDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# === Ã‰criture dans le journal ===
function Write-MaintainLog {
    param([string]$Msg,[string]$Level="INFO")
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),$Level,$Msg
    Add-Content -Path $LogFile -Value $line
}

# === Chargement des rapports prÃ©cÃ©dents ===
function Get-LastDeployInfo {
    $deploy = Join-Path $LogsDir "Deploy_Report.json"
    if (Test-Path $deploy) {
        try { (Get-Content $deploy -Raw | ConvertFrom-Json) } catch { $null }
    }
}

# === Test du chargement dâ€™un module ===
function Test-ModuleLoad {
    param([string]$Path)
    try {
        Import-Module $Path -Force -ErrorAction Stop
        return $true
    } catch {
        Write-MaintainLog "Erreur lors du chargement de $Path : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# === Fonction principale ===
function Invoke-AthenaMaintainer {

    Write-MaintainLog "----- DÃ‰BUT DU CYCLE AUTO-MAINTENANCE -----"

    $Deploy = Get-LastDeployInfo
    if (-not $Deploy) {
        Write-MaintainLog "Aucun rapport de dÃ©ploiement trouvÃ©, maintenance complÃ¨te." "INFO"
    } else {
        Write-MaintainLog "Analyse post-dÃ©ploiement de $($Deploy.Phase)" "INFO"
    }

    # 1ï¸âƒ£ Parcours des modules
    $ModulesPath = Join-Path $RootDir "Modules"
    $Modules = Get-ChildItem -Path $ModulesPath -Filter "*.psm1" -File
    $Report = @()

    foreach ($m in $Modules) {
        if ($m.Name -like "*-Fige.psm1") {
            Write-MaintainLog "IgnorÃ© (module figÃ©) : $($m.Name)" "SKIP"
            continue
        }
        Write-MaintainLog "Test du module : $($m.Name)" "INFO"
        $ok = Test-ModuleLoad -Path $m.FullName
        $Report += [PSCustomObject]@{
            Module = $m.Name
            Status = if ($ok) { "OK" } else { "ERROR" }
        }
    }

    # 2ï¸âƒ£ Validation dâ€™intÃ©gritÃ©
    if (Get-Command Invoke-AthenaIntegrity -ErrorAction SilentlyContinue) {
        try {
            Invoke-AthenaIntegrity | Out-Null
            Write-MaintainLog "IntÃ©gritÃ© globale vÃ©rifiÃ©e." "OK"
        } catch {
            Write-MaintainLog "Erreur dâ€™intÃ©gritÃ© : $($_.Exception.Message)" "ERROR"
        }
    }

    # 3ï¸âƒ£ GÃ©nÃ©ration du rapport JSON
    $Out = @{
        Timestamp = (Get-Date)
        Phase     = if ($Deploy) { $Deploy.Phase } else { "Inconnue" }
        Modules   = $Report
    }
    $Out | ConvertTo-Json -Depth 4 | Set-Content $ReportFile -Encoding UTF8

    # 4ï¸âƒ£ Notification cockpit (si dispo)
    if (Get-Command Invoke-AthenaSpeak -ErrorAction SilentlyContinue) {
        Invoke-AthenaSpeak -Text "Maintenance Athena terminÃ©e avec succÃ¨s."
    }

    Write-MaintainLog "----- FIN DU CYCLE AUTO-MAINTENANCE -----"
}

Export-ModuleMember -Function Invoke-AthenaMaintainer




