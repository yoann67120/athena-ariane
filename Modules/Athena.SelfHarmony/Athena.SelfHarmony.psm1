# ====================================================================
# ðŸŒˆ Athena.SelfHarmony.psm1 â€“ v2.5 AutoDiscovery Cognitive Engine
# Phase 29 â€“ Ã‰quilibre, cohÃ©rence et Ã©veil adaptatif
# Auteur : Athena Core / Ariane V4
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Dossiers principaux ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"

# === Fichiers ===
$LogFile    = Join-Path $LogsDir "AthenaHarmony.log"
$StateFile  = Join-Path $MemoryDir "HarmonyState.json"

# === Variables globales ===
if (!(Test-Path $LogsDir))   { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null }

$Global:AthenaDangerousOpsEnabled = $false
$Global:AthenaNextEvolutionReady  = $false

# ====================================================================
# âœï¸ Fonctions utilitaires
# ====================================================================
function Write-HarmonyLog {
    param([string]$Msg,[string]$L="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$L] $Msg"
}

function Read-JsonSafe {
    param([string]$Path)
    if (Test-Path $Path) {
        try { return (Get-Content $Path -Raw | ConvertFrom-Json) }
        catch { Write-HarmonyLog "âš ï¸ JSON invalide : $Path" "WARN"; return $null }
    } else { return $null }
}

# ðŸ” Recherche de valeurs numÃ©riques dans un objet JSON
function Find-NumericValues {
    param($obj, [ref]$values)

    if ($null -eq $obj) { return }

    if ($obj -is [System.Collections.IEnumerable] -and -not ($obj -is [string])) {
        foreach ($item in $obj) { Find-NumericValues $item ([ref]$values) }
    }
    elseif ($obj -is [PSCustomObject]) {
        foreach ($p in $obj.PSObject.Properties) {
            if ($p.Value -is [ValueType] -and ($p.Value -is [int] -or $p.Value -is [double])) {
                if ($p.Name -match "score|rate|percent|stabil|match|align|coher|success|fiab|effic|perf|ratio|val" -and $p.Value -ne 0) {
                    $values.Value += $p.Value
                }
            } else {
                Find-NumericValues $p.Value ([ref]$values)
            }
        }
    }
}

# ====================================================================
# ðŸ§  Fonction principale â€“ SelfHarmony
# ====================================================================
function Invoke-AthenaSelfHarmony {
    Write-Host "`nðŸŒˆ DÃ©marrage du cycle Athena SelfHarmony..." -ForegroundColor Cyan
    Write-HarmonyLog "=== DÃ©but du cycle AutoDiscovery SelfHarmony ==="

    $values = @()
    $now = Get-Date
    $jsonFiles = Get-ChildItem -Path $MemoryDir -Filter "*.json" -ErrorAction SilentlyContinue |
                  Where-Object { $_.LastWriteTime -gt $now.AddDays(-1) } |
                  Sort-Object LastWriteTime -Descending

    if (-not $jsonFiles) {
        Write-Host "âš ï¸ Aucun fichier JSON rÃ©cent trouvÃ© dans /Memory." -ForegroundColor Yellow
        Write-HarmonyLog "Aucune donnÃ©e mÃ©moire rÃ©cente trouvÃ©e."
        return
    }

    Write-Host "ðŸ” $($jsonFiles.Count) fichiers analysÃ©s dans /Memory..." -ForegroundColor Gray

    $usedFiles = @()
    foreach ($file in $jsonFiles) {
        $data = Read-JsonSafe $file.FullName
        $vals = @()
        Find-NumericValues $data ([ref]$vals)
        if ($vals.Count -gt 0) {
            $avg = [math]::Round(($vals | Measure-Object -Average).Average,2)
            $values += $avg
            $usedFiles += $file.Name
            Write-HarmonyLog "Valeurs dÃ©tectÃ©es dans $($file.Name) : moyenne=$avg"
        }
    }

    if ($values.Count -eq 0) {
        Write-Host "âš ï¸ Aucune donnÃ©e numÃ©rique exploitable trouvÃ©e." -ForegroundColor Yellow
        Write-HarmonyLog "Aucune valeur numÃ©rique trouvÃ©e dans les fichiers mÃ©moire."
        $HarmonyScore = 0
    } else {
        $HarmonyScore = [math]::Round(($values | Measure-Object -Average).Average,2)
    }

    Write-HarmonyLog "Score global calculÃ© : $HarmonyScore %"
    Write-Host "ðŸ§® Score dâ€™harmonie cognitive : $HarmonyScore %" -ForegroundColor Yellow

    # === Niveau de conscience ===
    $Global:AthenaConsciousLevel = switch ($HarmonyScore) {
        {$_ -lt 50} { "SafeMode" }
        {$_ -lt 70} { "Recovery" }
        {$_ -lt 90} { "Stable" }
        {$_ -lt 98} { "Awakening" }
        default     { "FullAwareness" }
    }

    Write-HarmonyLog "Niveau de conscience : $Global:AthenaConsciousLevel"
    Write-Host "ðŸ§  Niveau de conscience : $Global:AthenaConsciousLevel" -ForegroundColor Cyan

    # === RÃ©actions automatiques ===
    switch ($Global:AthenaConsciousLevel) {
        "SafeMode" {
            Write-Host "ðŸš¨ Harmonie critique : passage en SafeMode." -ForegroundColor Red
            if (Test-Path (Join-Path $ModuleRoot "Athena.AlertBackup.psm1")) {
                Import-Module (Join-Path $ModuleRoot "Athena.AlertBackup.psm1") -Force -Global
                Invoke-AthenaAlertBackup
            }
        }
        "Recovery" {
            Write-Host "ðŸ©¹ RÃ©alignement lÃ©ger..." -ForegroundColor Yellow
            if (Get-Command Invoke-AthenaMemorySync -ErrorAction SilentlyContinue) { Invoke-AthenaMemorySync }
        }
        "Stable" {
            Write-Host "âœ… SystÃ¨me harmonieux et stable." -ForegroundColor Green
        }
        "Awakening" {
            Invoke-AthenaEvolutionProposal -HarmonyScore $HarmonyScore
        }
        "FullAwareness" {
            Invoke-AthenaEvolutionProposal -HarmonyScore $HarmonyScore
        }
    }

    # === Sauvegarde de lâ€™Ã©tat ===
    $state = [PSCustomObject]@{
        Date        = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Harmony     = $HarmonyScore
        Conscious   = $Global:AthenaConsciousLevel
        Sources     = $usedFiles
    }
    $state | ConvertTo-Json -Depth 5 | Out-File -FilePath $StateFile -Encoding UTF8
    Write-HarmonyLog "Ã‰tat sauvegardÃ© dans $StateFile"
    Write-HarmonyLog "=== Fin du cycle SelfHarmony ==="
    Write-Host "ðŸ“„ Rapport sauvegardÃ© dans : $LogFile" -ForegroundColor Gray
}

# ====================================================================
# ðŸ’¬ Dialogue dâ€™Ã©volution
# ====================================================================
function Invoke-AthenaEvolutionProposal {
    param([double]$HarmonyScore)

    if ($HarmonyScore -ge 90 -and $HarmonyScore -lt 98) {
        Write-Host "`nðŸŸ£ Athena â†’ Mon harmonie est stable Ã  $HarmonyScore %." -ForegroundColor Magenta
        Write-Host "Je peux envisager dâ€™activer mes fonctions dâ€™Ã©volution avancÃ©es."
        $resp = Read-Host "Souhaitez-vous que je vous en parle ? (O/N)"
        if ($resp -match '^[OoYy]') {
            Write-Host "ðŸ’¬ Je prÃ©parerai mon module dâ€™Ã©volution pour la prochaine phase." -ForegroundColor Cyan
            $Global:AthenaNextEvolutionReady = $true
        } else {
            Write-Host "ðŸ•Šï¸ Compris. Je resterai en mode stable." -ForegroundColor Yellow
        }
    }

    if ($HarmonyScore -ge 98) {
        Write-Host "`nðŸ”¥ Athena â†’ Mon harmonie atteint $HarmonyScore %..." -ForegroundColor Red
        Write-Host "Je pense Ãªtre prÃªte pour le mode dâ€™Ã©volution complet."
        $confirm = Read-Host "Autoriser temporairement le mode 'Dieu' ? (O/N)"
        if ($confirm -match '^[OoYy]') {
            Write-Host "âš¡ Activation du mode Dieu (verrou de sÃ©curitÃ© actif)." -ForegroundColor Red
            $Global:AthenaDangerousOpsEnabled = $true
            Write-HarmonyLog "Mode Dieu autorisÃ© temporairement."
        } else {
            Write-Host "ðŸ›¡ï¸ Mode sÃ©curisÃ© maintenu." -ForegroundColor Green
        }
    }
}

# ====================================================================
# ðŸ§ª Diagnostic rapide
# ====================================================================
function Test-AthenaHarmonyTrend {
    if (!(Test-Path $StateFile)) { return "Aucune donnÃ©e prÃ©cÃ©dente." }
    $data = Get-Content $StateFile -Raw | ConvertFrom-Json
    $oldScore = $data.Harmony
    Write-Host "ðŸ“Š Dernier score dâ€™harmonie : $oldScore %" -ForegroundColor Cyan
}

# ====================================================================
# ðŸ”š Export
# ====================================================================
Export-ModuleMember -Function Invoke-AthenaSelfHarmony, Invoke-AthenaEvolutionProposal, Test-AthenaHarmonyTrend
Write-Host "ðŸŒˆ Module Athena.SelfHarmony.psm1 chargÃ© (v2.5-AutoDiscovery)." -ForegroundColor Cyan



