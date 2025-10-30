# ====================================================================
# ðŸ§  Athena.SecurityGuardian.psm1 â€“ v1.0-Integrity-Core
# --------------------------------------------------------------------
# Objectif :
#   Surveiller et protÃ©ger lâ€™intÃ©gritÃ© du systÃ¨me Athena.
#   VÃ©rifie les signatures SHA1/MD5, dÃ©tecte les modifications,
#   restaure automatiquement les fichiers corrompus,
#   et journalise toute anomalie dÃ©tectÃ©e.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === RÃ©pertoires et fichiers ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ModulesDir = Join-Path $RootDir "Modules"
$ConfigDir  = Join-Path $RootDir "Config"
$BackupDir  = Join-Path $MemoryDir "Archives\Security"
$LogFile    = Join-Path $LogsDir "SecurityGuardian.log"
$SigFile    = Join-Path $MemoryDir "ModuleSignatures.json"

foreach ($p in @($LogsDir,$MemoryDir,$ModulesDir,$BackupDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# === Journal interne ===
function Write-SecurityLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# 1ï¸âƒ£ Calcul et enregistrement des signatures
# ====================================================================
function Register-FileSignature {
    param([string]$Path)
    if (!(Test-Path $Path)) { Write-SecurityLog "âŒ Fichier introuvable : $Path" "ERROR"; return }

    $sha1 = (Get-FileHash -Algorithm SHA1 -Path $Path).Hash
    $md5  = (Get-FileHash -Algorithm MD5  -Path $Path).Hash

    $sigs = @()
    if (Test-Path $SigFile) { try { $sigs = Get-Content $SigFile -Raw | ConvertFrom-Json } catch {} }

    $sigs = $sigs | Where-Object { $_.Path -ne $Path }
    $sigs += [pscustomobject]@{
        Path = $Path
        SHA1 = $sha1
        MD5  = $md5
        Date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    $sigs | ConvertTo-Json -Depth 4 | Out-File $SigFile -Encoding utf8
    Write-SecurityLog "âœ… Signature enregistrÃ©e pour $Path"
}

# ====================================================================
# 2ï¸âƒ£ VÃ©rification de lâ€™intÃ©gritÃ© dâ€™un fichier
# ====================================================================
function Check-FileIntegrity {
    param([string]$Path)
    if (!(Test-Path $SigFile)) { Write-SecurityLog "âš ï¸ Aucune signature connue." "WARN"; return $true }
    $sigs = Get-Content $SigFile -Raw | ConvertFrom-Json
    $entry = $sigs | Where-Object { $_.Path -eq $Path }
    if ($null -eq $entry) { Write-SecurityLog "âš ï¸ Pas dâ€™entrÃ©e connue pour $Path"; return $true }

    $currentSHA1 = (Get-FileHash -Algorithm SHA1 -Path $Path).Hash
    $currentMD5  = (Get-FileHash -Algorithm MD5  -Path $Path).Hash

    if ($currentSHA1 -ne $entry.SHA1 -or $currentMD5 -ne $entry.MD5) {
        Write-SecurityLog "âŒ IntÃ©gritÃ© compromise pour $Path" "ERROR"
        return $false
    }

    Write-SecurityLog "âœ… $Path vÃ©rifiÃ© : intÃ©gritÃ© confirmÃ©e."
    return $true
}

# ====================================================================
# 3ï¸âƒ£ VÃ©rification de tous les modules
# ====================================================================
function Check-ModuleIntegrity {
    Write-SecurityLog "ðŸ”Ž VÃ©rification de lâ€™intÃ©gritÃ© des modules..."
    $files = Get-ChildItem $ModulesDir -Filter "*.psm1" -Recurse
    foreach ($f in $files) {
        $ok = Check-FileIntegrity -Path $f.FullName
        if (-not $ok) { Auto-RestoreBackup -File $f.FullName }
    }
}

# ====================================================================
# 4ï¸âƒ£ Sauvegarde dâ€™un fichier sain
# ====================================================================
function Backup-Module {
    param([string]$Path)
    if (!(Test-Path $Path)) { return }
    $dest = Join-Path $BackupDir ("Backup_" + (Split-Path $Path -Leaf) + "_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
    Copy-Item $Path $dest -Force
    Write-SecurityLog "ðŸ’¾ Sauvegarde : $dest"
}

# ====================================================================
# 5ï¸âƒ£ Restauration automatique en cas de corruption
# ====================================================================
function Auto-RestoreBackup {
    param([string]$File)
    $name = Split-Path $File -Leaf
    $last = Get-ChildItem $BackupDir | Where-Object { $_.Name -like "*$name*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -ne $last) {
        Copy-Item $last.FullName $File -Force
        Write-SecurityLog "â™»ï¸ Fichier $name restaurÃ© depuis $($last.Name)"
    } else {
        Write-SecurityLog "âŒ Aucune sauvegarde trouvÃ©e pour $name" "ERROR"
    }
}

# ====================================================================
# 6ï¸âƒ£ VÃ©rification du registre open-source
# ====================================================================
function Verify-RegistryIntegrity {
    $reg = Join-Path $ConfigDir "OpenSourceRegistry.json"
    try { Get-Content $reg -Raw | ConvertFrom-Json | Out-Null; Write-SecurityLog "âœ… Registre JSON valide." }
    catch { Write-SecurityLog "âŒ Registre corrompu : $_" "ERROR"; Auto-RestoreBackup -File $reg }
}

# ====================================================================
# 7ï¸âƒ£ Analyse de sÃ©curitÃ© complÃ¨te
# ====================================================================
function Invoke-SecurityScan {
    Write-Host "`nðŸ›¡ï¸ Lancement du scan de sÃ©curitÃ© Athena..." -ForegroundColor Cyan
    Write-SecurityLog "=== DÃ©but SecurityScan ==="

    Check-ModuleIntegrity
    Verify-RegistryIntegrity

    Write-SecurityLog "=== Fin SecurityScan ==="
    Write-Host "âœ… Scan de sÃ©curitÃ© terminÃ©." -ForegroundColor Green
}

# ====================================================================
# 8ï¸âƒ£ Notification dâ€™anomalie (future intÃ©gration cockpit/voix)
# ====================================================================
function Alert-SecurityAnomaly {
    param([string]$Message)
    Write-SecurityLog "ðŸš¨ ALERTE : $Message" "ERROR"
    $Notify = Join-Path $ModuleRoot "Cockpit.Notify.psm1"
    if (Test-Path $Notify) {
        Import-Module $Notify -Force -Global
        if (Get-Command Invoke-CockpitNotify -ErrorAction SilentlyContinue) {
            Invoke-CockpitNotify -Message $Message -Tone "error" -Color "red"
        }
    }
}

# ====================================================================
# 9ï¸âƒ£ Cycle automatique
# ====================================================================
function Invoke-AthenaSecurityGuardian {
    Write-Host "`nðŸ›¡ï¸ ExÃ©cution du cycle complet SecurityGuardian..." -ForegroundColor Cyan
    Write-SecurityLog "=== DÃ©but cycle Guardian ==="

    $modules = Get-ChildItem $ModulesDir -Filter "*.psm1" -Recurse
    foreach ($m in $modules) {
        $ok = Check-FileIntegrity -Path $m.FullName
        if (-not $ok) {
            Backup-Module -Path $m.FullName
            Auto-RestoreBackup -File $m.FullName
            Alert-SecurityAnomaly "Module $($m.Name) restaurÃ© aprÃ¨s anomalie."
        }
    }

    Verify-RegistryIntegrity
    Write-SecurityLog "=== Fin cycle Guardian ==="
    Write-Host "âœ… Cycle Guardian terminÃ©." -ForegroundColor Green
}

# ====================================================================
# ðŸ”š Exports publics
# ====================================================================
Export-ModuleMember -Function `
    Register-FileSignature, `
    Check-FileIntegrity, `
    Check-ModuleIntegrity, `
    Backup-Module, `
    Auto-RestoreBackup, `
    Verify-RegistryIntegrity, `
    Invoke-SecurityScan, `
    Invoke-AthenaSecurityGuardian

Write-Host "ðŸ§± Module Athena.SecurityGuardian.psm1 chargÃ© (v1.0-Integrity-Core)." -ForegroundColor Cyan
Write-SecurityLog "Module SecurityGuardian v1.0 chargÃ©."



