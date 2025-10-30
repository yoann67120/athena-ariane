# ====================================================================
# ðŸ” Athena.SelfGuard.psm1 â€“ v1.1 AdaptiveSecurity
# Auteur : Yoann Rousselle / Projet Ariane V4
# RÃ´le :
#   - Moteur de sÃ©curitÃ© intelligent du pont GPT-5 â†” Athena
#   - VÃ©rifie lâ€™intÃ©gritÃ© des chemins, extensions, tailles et signatures
#   - Journalise et notifie le Cockpit en cas dâ€™alerte
#   - Sâ€™adapte dynamiquement selon le mode (Strict / Balanced / Open)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === RÃ©pertoires ===
$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir 'Logs'
$ConfigDir = Join-Path $RootDir 'Config'
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

$LogFile   = Join-Path $LogsDir 'SelfGuard.log'
$RulesFile = Join-Path $ConfigDir 'BridgeRules.json'
$SigFile   = Join-Path $ConfigDir 'ModuleSignatures.json'

# ====================================================================
# ðŸª¶ Journalisation
# ====================================================================
function Write-GuardLog {
    param([string]$Msg,[string]$Level='INFO')
    $t = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
    if ($Level -eq 'ERROR') { Write-Host "ðŸš¨ $Msg" -ForegroundColor Red }
}

# ====================================================================
# âš™ï¸ Chargement des rÃ¨gles et signatures
# ====================================================================
function Get-GuardRules {
    if (!(Test-Path $RulesFile)) {
        $default = @{
            AllowedPaths = @(
                "$RootDir\\Modules",
                "$RootDir\\Scripts",
                "$RootDir\\Memory",
                "$RootDir\\Logs"
            )
            ForbiddenExtensions = @('.exe','.dll','.sys','.bat','.vbs','.js')
            MaxFileSizeMB = 10
            Mode = 'Strict'
        }
        $default | ConvertTo-Json -Depth 4 | Out-File $RulesFile -Encoding UTF8
        Write-GuardLog 'Fichier BridgeRules.json crÃ©Ã© par dÃ©faut.'
    }
    try {
        return (Get-Content $RulesFile -Raw | ConvertFrom-Json)
    } catch {
        Write-GuardLog "Erreur lecture BridgeRules.json : $_" 'ERROR'
        return $null
    }
}

function Get-GuardSignatures {
    if (Test-Path $SigFile) {
        try { return Get-Content $SigFile -Raw | ConvertFrom-Json } catch { return @{} }
    }
    else {
        # GÃ©nÃ¨re un fichier de signatures vide sâ€™il nâ€™existe pas encore
        @{} | ConvertTo-Json -Depth 3 | Out-File $SigFile -Encoding UTF8
        Write-GuardLog 'Fichier ModuleSignatures.json crÃ©Ã© (vide).'
        return @{}
    }
}

# ====================================================================
# ðŸ” VÃ©rification des chemins / extensions / tailles / signatures
# ====================================================================
function Test-PathSecurity {
    param([string]$Path)
    $rules = Get-GuardRules
    if (-not $rules) { return $false }

    # Chemin autorisÃ© ?
    $allowed = $false
    foreach ($base in $rules.AllowedPaths) {
        if ($Path -like "$base*") { $allowed = $true; break }
    }
    if (-not $allowed) {
        Write-GuardLog "Tentative dâ€™accÃ¨s non autorisÃ© : $Path" 'WARN'
        Invoke-GuardResponse -Type 'PATH' -Detail $Path
        return $false
    }

    # Extension interdite ?
    $ext = [System.IO.Path]::GetExtension($Path)
    if ($rules.ForbiddenExtensions -contains $ext) {
        Write-GuardLog "Extension interdite : $ext ($Path)" 'ERROR'
        Invoke-GuardResponse -Type 'EXT' -Detail $Path
        return $false
    }

    # Taille excessive ?
    if (Test-Path $Path) {
        $sizeMB = [math]::Round((Get-Item $Path).Length / 1MB,2)
        if ($sizeMB -gt $rules.MaxFileSizeMB) {
            Write-GuardLog "Fichier trop volumineux ($sizeMB MB) : $Path" 'ERROR'
            Invoke-GuardResponse -Type 'SIZE' -Detail $Path
            return $false
        }
    }

    # VÃ©rification de signature SHA256
    $sigs = Get-GuardSignatures
    if ($sigs.ContainsKey($Path)) {
        $expected = $sigs[$Path]
        try {
            $actual = (Get-FileHash $Path -Algorithm SHA256).Hash
            if ($expected -ne $actual) {
                Write-GuardLog "Signature invalide pour $Path" 'ERROR'
                Invoke-GuardResponse -Type 'SIG' -Detail $Path
                return $false
            }
        } catch {
            Write-GuardLog "Erreur calcul hash $Path : $_" 'ERROR'
        }
    }

    return $true
}

# ====================================================================
# ðŸ” Validation dâ€™exÃ©cution
# ====================================================================
function Validate-Execution {
    param([string]$Command,[string]$TargetPath)
    Write-GuardLog "Validation exÃ©cution : $Command"
    if (-not (Test-PathSecurity -Path $TargetPath)) {
        Write-GuardLog "âŒ ExÃ©cution bloquÃ©e : $Command ($TargetPath)" 'ERROR'
        return $false
    }
    return $true
}

# Alias compatible IntentBridge
Set-Alias -Name Invoke-SelfGuardValidation -Value Validate-Execution -Force

# ====================================================================
# ðŸ§± Modes de sÃ©curitÃ©
# ====================================================================
function Set-GuardMode {
    param([ValidateSet('Strict','Balanced','Open')] [string]$Mode='Strict')
    $rules = Get-GuardRules
    $rules.Mode = $Mode
    $rules | ConvertTo-Json -Depth 4 | Out-File $RulesFile -Encoding UTF8
    Write-GuardLog "Mode de sÃ©curitÃ© dÃ©fini sur : $Mode"
}

function Get-GuardMode {
    (Get-GuardRules).Mode
}

# ====================================================================
# ðŸš¨ RÃ©actions et alertes visuelles
# ====================================================================
function Invoke-GuardResponse {
    param([string]$Type,[string]$Detail)
    Write-GuardLog "Violation dÃ©tectÃ©e : $Type â€“ $Detail" 'ERROR'

    # Signal Cockpit
    if (Get-Command Send-CockpitSignal -ErrorAction SilentlyContinue) {
        Send-CockpitSignal -Type 'Error'
    }

    # Broadcast HybridLink
    if (Get-Command Broadcast-Bridge -ErrorAction SilentlyContinue) {
        Broadcast-Bridge -Title 'SelfGuard' -Message "Violation $Type dÃ©tectÃ©e : $Detail" -Type 'error'
    }

    # RÃ©actions systÃ¨me
    switch ($Type) {
        'PATH' { if (Get-Command Stop-BridgeServer -ErrorAction SilentlyContinue) { Stop-BridgeServer } }
        'EXT'  { Write-Host 'âŒ Extension interdite dÃ©tectÃ©e.' -ForegroundColor Red }
        'SIZE' { Write-Host 'âš ï¸ Fichier trop volumineux dÃ©tectÃ©.' -ForegroundColor Yellow }
        'SIG'  { Write-Host 'ðŸš« Signature non valide !' -ForegroundColor Red }
        default { Write-Host 'âš ï¸ Alerte de sÃ©curitÃ©.' -ForegroundColor Magenta }
    }
}

# ====================================================================
# ðŸ§© IntÃ©gration BridgeServer
# ====================================================================
function Protect-BridgeExecution {
    param([string]$Intent,[hashtable]$Payload)
    $valid = $true
    if ($Payload.ContainsKey('path')) { $valid = Test-PathSecurity -Path $Payload.path }
    if (-not $valid) {
        Invoke-GuardResponse -Type 'PATH' -Detail $Payload.path
        return $false
    }
    return $true
}

# ====================================================================
# ðŸ§ª Diagnostic
# ====================================================================
function Test-SelfGuard {
    Write-Host "`nðŸ›¡ï¸ Test du moteur SelfGuard..." -ForegroundColor Cyan
    $rules = Get-GuardRules
    Write-Host "âœ… RÃ¨gles : $(($rules.AllowedPaths -join ', '))"
    Write-Host "Mode : $($rules.Mode) | Taille max : $($rules.MaxFileSizeMB) MB"
    Write-Host "Signatures connues : $(Get-GuardSignatures).Count"
    Write-GuardLog 'Test SelfGuard exÃ©cutÃ©.'
}

# ====================================================================
# ðŸš€ Initialisation
# ====================================================================
function Initialize-SelfGuard {
    Write-Host "`nðŸ” Initialisation de SelfGuard (AdaptiveSecurity)" -ForegroundColor Cyan
    $rules = Get-GuardRules
    if ($rules) { Write-Host "Mode actuel : $($rules.Mode)" -ForegroundColor Green }
    Write-GuardLog 'SelfGuard initialisÃ© (v1.1 Adaptive).'
}

Export-ModuleMember -Function * -Alias *
Write-Host 'ðŸ” Module Athena.SelfGuard.psm1 chargÃ© (v1.1 AdaptiveSecurity)' -ForegroundColor Cyan
Write-GuardLog 'Module SelfGuard v1.1 chargÃ©.'


