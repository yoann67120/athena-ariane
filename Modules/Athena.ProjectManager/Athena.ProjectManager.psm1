# ====================================================================
# ðŸ§© Athena.ProjectManager.psm1 â€“ v2.0-ActionPlannerCore-Universal
# --------------------------------------------------------------------
# Auteur : Projet Ariane V4 / Athena Core
# RÃ´le :
#   - Gestion complÃ¨te des projets (crÃ©ation, mise Ã  jour, suppression)
#   - GÃ©nÃ©ration automatique de structure + mÃ©tadonnÃ©es
#   - Interaction avec le cockpit et les autres modules
#   - PrÃ©paration des extensions GitHub / Supabase
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Dossiers principaux -------------------------------------------------
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$ProjectsDir = Join-Path $RootDir "Projects"
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"

$ProjectsLog = Join-Path $LogsDir "Projects.log"
$ProjectsMem = Join-Path $MemoryDir "ProjectsHistory.json"

foreach ($p in @($ProjectsDir,$LogsDir,$MemoryDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# ====================================================================
# âœï¸ Fonction de log
# ====================================================================
function Write-ProjectLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $ProjectsLog -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸš€ CrÃ©ation dâ€™un nouveau projet
# ====================================================================
function New-AthenaProject {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][ValidateSet("Web","IA","Automatisation","Script","Mixte")][string]$Type
    )

    $ProjectPath = Join-Path $ProjectsDir $Name
    if (Test-Path $ProjectPath) {
        Write-Host "âš ï¸ Le projet '$Name' existe dÃ©jÃ ." -ForegroundColor Yellow
        Write-ProjectLog "âš ï¸ Tentative de recrÃ©ation du projet $Name (dÃ©jÃ  existant)."
        return
    }

    # --- CrÃ©ation des dossiers ---
    New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjectPath "logs") -Force | Out-Null

    # --- Fichiers de base ---
    $html = "<!DOCTYPE html>`n<html><head><meta charset='utf-8'><title>$Name</title><link rel='stylesheet' href='styles.css'></head><body><h1>Projet $Name</h1><p>CrÃ©Ã© automatiquement par Athena.</p></body></html>"
    Set-Content (Join-Path $ProjectPath "index.html") $html -Encoding UTF8
    Set-Content (Join-Path $ProjectPath "styles.css") "body { font-family: Arial; background:#111; color:#eee; }" -Encoding UTF8
    Set-Content (Join-Path $ProjectPath "script.js") "console.log('Projet $Name initialisÃ©.');" -Encoding UTF8
    Set-Content (Join-Path $ProjectPath "README.md") "# $Name`nProjet $Type gÃ©nÃ©rÃ© automatiquement par Athena." -Encoding UTF8

    $meta = [ordered]@{
        Nom = $Name
        Type = $Type
        DateCreation = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Auteur = "Athena"
        Etat = "InitialisÃ©"
        Fichiers = @("index.html","styles.css","script.js","README.md","meta.json")
    }
    $meta | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $ProjectPath "meta.json") -Encoding UTF8

    # --- MÃ©morisation ---
    $history = @()
    if (Test-Path $ProjectsMem) {
        $history = Get-Content $ProjectsMem -Raw | ConvertFrom-Json
    }
    $history += $meta
    $history | ConvertTo-Json -Depth 4 | Out-File $ProjectsMem -Encoding UTF8

    Write-ProjectLog "ðŸ§± Projet crÃ©Ã© : $Name ($Type)"
    Write-Host "âœ… Projet '$Name' crÃ©Ã© avec succÃ¨s." -ForegroundColor Green

    Notify-AthenaProjectCockpit -Name $Name -Status "CrÃ©Ã©" -Type $Type
}

# ====================================================================
# ðŸ“œ Liste et informations
# ====================================================================
function Get-AthenaProjectList {
    Get-ChildItem -Path $ProjectsDir -Directory | Select-Object Name, @{n='Path';e={$_.FullName}}
}

function Get-AthenaProjectInfo {
    param([Parameter(Mandatory=$true)][string]$Name)
    $metaFile = Join-Path (Join-Path $ProjectsDir $Name) "meta.json"
    if (Test-Path $metaFile) {
        return Get-Content $metaFile -Raw | ConvertFrom-Json
    } else {
        Write-Host "âŒ Projet introuvable : $Name" -ForegroundColor Red
    }
}

# ====================================================================
# ðŸ” Mise Ã  jour / reconstruction
# ====================================================================
function Update-AthenaProject {
    param([string]$Name)
    $meta = Get-AthenaProjectInfo -Name $Name
    if (!$meta) { return }

    $meta.LastUpdate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $meta.Etat = "Mis Ã  jour"
    $meta | ConvertTo-Json -Depth 4 | Out-File (Join-Path $ProjectsDir "$Name\meta.json") -Encoding UTF8

    Write-ProjectLog "â™»ï¸ Projet $Name mis Ã  jour."
    Notify-AthenaProjectCockpit -Name $Name -Status "Mis Ã  jour"
}

# ====================================================================
# ðŸ—ï¸ Construction / Build
# ====================================================================
function Invoke-AthenaProjectBuild {
    param([string]$Name)
    $meta = Get-AthenaProjectInfo -Name $Name
    if (!$meta) { return }

    $buildLog = Join-Path (Join-Path $ProjectsDir $Name) "logs\build.log"
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content $buildLog "[$t] DÃ©marrage du build du projet $Name..."

    # Simulation dâ€™un processus de build
    Start-Sleep -Seconds 3
    Add-Content $buildLog "[$t] Build terminÃ© avec succÃ¨s."
    Write-Host "âœ… Build du projet '$Name' terminÃ©." -ForegroundColor Green
    Write-ProjectLog "ðŸ—ï¸ Build terminÃ© pour $Name."
    Notify-AthenaProjectCockpit -Name $Name -Status "Build terminÃ©"
}

# ====================================================================
# ðŸ—ƒï¸ Archivage et suppression
# ====================================================================
function Archive-AthenaProject {
    param([string]$Name)
    $projectPath = Join-Path $ProjectsDir $Name
    if (!(Test-Path $projectPath)) {
        Write-Host "âŒ Projet introuvable : $Name" -ForegroundColor Red
        return
    }

    $zipPath = Join-Path $ProjectsDir "$Name-$((Get-Date).ToString('yyyyMMdd_HHmmss')).zip"
    Compress-Archive -Path $projectPath -DestinationPath $zipPath -Force
    Write-ProjectLog "ðŸ“¦ Projet archivÃ© : $Name -> $zipPath"
    Write-Host "âœ… Projet '$Name' archivÃ©." -ForegroundColor Green
}

function Remove-AthenaProject {
    param([string]$Name)
    $projectPath = Join-Path $ProjectsDir $Name
    if (Test-Path $projectPath) {
        Remove-Item -Path $projectPath -Recurse -Force
        Write-ProjectLog "ðŸ—‘ï¸ Projet supprimÃ© : $Name"
        Write-Host "ðŸ—‘ï¸ Projet '$Name' supprimÃ©." -ForegroundColor Yellow
        Notify-AthenaProjectCockpit -Name $Name -Status "SupprimÃ©"
    } else {
        Write-Host "âŒ Projet introuvable : $Name" -ForegroundColor Red
    }
}

# ====================================================================
# ðŸ§  Conversion dâ€™une intention â†’ projet
# ====================================================================
function Invoke-AthenaProjectFromIntent {
    param([string]$Texte)

    # DÃ©termination du type de projet
    $type = "Web"
    if ($Texte -match "ia|intelligence") { $type = "IA" }
    elseif ($Texte -match "script|powershell") { $type = "Script" }
    elseif ($Texte -match "n8n|automatisation|workflow") { $type = "Automatisation" }

    # Nettoyage du texte pour extraire le nom
$nom = $Texte
$nom = $nom -replace "(cree|crÃ©e|creation|creer|projet|nouveau|nommÃ©|appelÃ©|web|ia|script|workflow|automatisation|site)",""
$nom = $nom.Trim()
$nom = $nom -replace "^(un|une|le|la|mon|ma|notre|nouveau|nouvelle)\s",""
$nom = $nom -replace "\s+"," "  # supprime les espaces multiples


    if (-not $nom -or $nom.Length -lt 2) {
        $nom = "Projet_" + (Get-Random -Maximum 9999)
    }

    Write-Host "ðŸ§© CrÃ©ation de projet Ã  partir de la commande : '$Texte'"
    New-AthenaProject -Name $nom -Type $type
}


# ====================================================================
# ðŸ’¬ Notification cockpit
# ====================================================================
function Notify-AthenaProjectCockpit {
    param([string]$Name,[string]$Status,[string]$Type="")

    try {
        $notifyModule = Join-Path $RootDir "Modules\Cockpit.Notify.psm1"
        if (Test-Path $notifyModule) {
            Import-Module $notifyModule -Force -Global
            if (Get-Command Invoke-CockpitNotify -ErrorAction SilentlyContinue) {
                Invoke-CockpitNotify -Message "Projet $Name â†’ $Status" -Color "green"
            }
        } else {
            Write-ProjectLog "â„¹ï¸ Cockpit non disponible pour notifier $Name ($Status)."
        }
    } catch {
        Write-ProjectLog "âŒ Erreur de notification : $_"
    }
}

# ====================================================================
# ðŸ”š Exportation des fonctions
# ====================================================================
Export-ModuleMember -Function `
    New-AthenaProject, Get-AthenaProjectList, Get-AthenaProjectInfo, `
    Update-AthenaProject, Invoke-AthenaProjectBuild, `
    Archive-AthenaProject, Remove-AthenaProject, `
    Invoke-AthenaProjectFromIntent, Notify-AthenaProjectCockpit

Write-Host "ðŸ§© Module Athena.ProjectManager.psm1 chargÃ© (v2.0-ActionPlannerCore-Universal)." -ForegroundColor Cyan


