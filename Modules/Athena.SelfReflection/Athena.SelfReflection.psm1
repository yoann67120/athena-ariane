# ====================================================================
# ðŸ§  Athena.SelfReflection.psm1 â€“ v2.0â€“SelfAdaptive
# --------------------------------------------------------------------
# Objectif :
#   Offrir Ã  Athena une conscience Ã©motionnelle autonome :
#   analyse, introspection, ajustement et cohÃ©rence globale.
#   Ce module devient le cÅ“ur de lâ€™Ã©quilibre Ã©motionnel dâ€™Athena.
# --------------------------------------------------------------------
# Auteur : Yoann Rousselle
# Version : v2.0 â€“ SelfAdaptive
# Date : 2025-10-17
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ====================================================================
# ðŸ“ Chemins principaux
# ====================================================================
$ModuleRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir      = Split-Path -Parent $ModuleRoot
$LogsDir      = Join-Path $RootDir "Logs"
$MemoryDir    = Join-Path $RootDir "Memory"
$EmotionLog   = Join-Path $LogsDir "EmotionHistory.log"
$ReflectionLog= Join-Path $LogsDir "EmotionReflection.log"
$EmotionHistoryJSON = Join-Path $MemoryDir "EmotionHistory.json"
$PermissionFile     = Join-Path $MemoryDir "Permissions.json"
$IntegrityLog = Join-Path $LogsDir "EmotionIntegrity.log"

foreach ($dir in @($LogsDir, $MemoryDir)) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# ====================================================================
# ðŸª¶ Fonction de log interne
# ====================================================================
function Write-ReflectionLog {
    param([string]$Msg)
    $t = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $ReflectionLog -Value "[$t] $Msg"
}

# ====================================================================
# ðŸ” Gestion des permissions (pour fonctions sensibles)
# ====================================================================
function Get-PermissionState {
    param([string]$FunctionName)
    if (!(Test-Path $PermissionFile)) { @{} | ConvertTo-Json | Out-File $PermissionFile -Encoding utf8 }
    try {
        $permissions = Get-Content $PermissionFile -Raw | ConvertFrom-Json
        return $permissions.$FunctionName
    } catch { return $null }
}

function Set-PermissionState {
    param([string]$FunctionName,[string]$State)
    try {
        $permissions = if (Test-Path $PermissionFile) {
            Get-Content $PermissionFile -Raw | ConvertFrom-Json
        } else { @{} }
        $permissions | Add-Member -NotePropertyName $FunctionName -NotePropertyValue $State -Force
        $permissions | ConvertTo-Json -Depth 3 | Out-File $PermissionFile -Encoding utf8
        Write-ReflectionLog "ðŸ” Permission mise Ã  jour : $FunctionName â†’ $State"
    } catch {
        Write-Warning "Impossible de mettre Ã  jour lâ€™autorisation pour $FunctionName"
    }
}

# ====================================================================
# ðŸ§© FONCTIONS UTILES ACTUELLES
# ====================================================================

function Read-EmotionHistory {
    Write-ReflectionLog "Lecture de lâ€™historique Ã©motionnel..."
    if (Test-Path $EmotionLog) { return Get-Content $EmotionLog -Raw }
    else {
        Write-Warning "Aucun fichier EmotionHistory.log trouvÃ©."
        return ""
    }
}

function Compute-HarmonyIndex {
    param([string]$RawData)
    Write-ReflectionLog "Calcul du HarmonyIndex..."

    if (-not $RawData) { return 100 }

    # Forcer le texte Ã  Ãªtre traitÃ© comme une liste de lignes
    $lines = $RawData -split "`r?`n"

    $countStable = ($lines | Select-String "Stable").Count
    $countSafe   = ($lines | Select-String "Safe").Count
    $countStress = ($lines | Select-String "Stress").Count
    $total = [math]::Max(1, ($countStable + $countSafe + $countStress))

    $score = [math]::Round((($countStable + $countSafe * 0.8) / $total) * 100, 2)
    return $score
}


function Detect-EmotionTrends {
    param([string]$RawData)
    Write-ReflectionLog "Analyse des tendances Ã©motionnelles..."
    if (-not $RawData) { return "Aucune donnÃ©e" }
    if ($RawData -match "FullAwareness") { return "â†‘ Ã©veil" }
    elseif ($RawData -match "Stress")    { return "â†“ stabilitÃ©" }
    elseif ($RawData -match "Stable")    { return "â†’ Ã©quilibre" }
    else                                 { return "â†” neutre" }
}

function Generate-ReflectionReport {
    param([int]$HarmonyIndex,[string]$Trend)
    $state = switch ($HarmonyIndex) {
        {$_ -ge 90} { "Serein" }
        {$_ -ge 70} { "Stable" }
        {$_ -ge 50} { "FatiguÃ©" }
        default     { "Inquiet" }
    }
    $entry = [pscustomobject]@{
        Date = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        HarmonyIndex = $HarmonyIndex
        EmotionTrend = $Trend
        ReflectionState = $state
    }
    $entry | ConvertTo-Json -Depth 3 | Add-Content -Path $ReflectionLog
    Write-ReflectionLog "Rapport gÃ©nÃ©rÃ© â†’ $state ($HarmonyIndex%)"
    return $entry
}

function Save-EmotionHistoryJSON {
    param([pscustomobject]$Report)
    $history = @()
    if (Test-Path $EmotionHistoryJSON) {
        try { $history = Get-Content $EmotionHistoryJSON -Raw | ConvertFrom-Json } catch { $history = @() }
    }
    $history += $Report
    $history | ConvertTo-Json -Depth 4 | Out-File $EmotionHistoryJSON -Encoding utf8
    Write-ReflectionLog "Sauvegarde EmotionHistory.json mise Ã  jour."
}

function Invoke-AthenaSelfRegulation {
    param([int]$HarmonyIndex)
    if ($HarmonyIndex -lt 60) {
        Write-ReflectionLog "âš™ï¸ Auto-rÃ©gulation dÃ©clenchÃ©e (HarmonyIndex < 60)"
        if (Get-Command Invoke-AthenaEmotion -ErrorAction SilentlyContinue) {
            Invoke-AthenaEmotion -State "Stable"
        } else {
            Write-Warning "Fonction Invoke-AthenaEmotion non trouvÃ©e."
        }
    } else {
        Write-ReflectionLog "Ã‰tat Ã©motionnel stable â€“ aucune rÃ©gulation nÃ©cessaire."
    }
}

function Get-HarmonyStatus {
    if (!(Test-Path $ReflectionLog)) { return "Aucun Ã©tat enregistrÃ©." }
    return (Get-Content $ReflectionLog | Select-Object -Last 1)
}

# ====================================================================
# ðŸ§© VÃ©rification dâ€™intÃ©gritÃ© Ã©motionnelle interne
# ====================================================================
function Test-EmotionIntegrity {
    Write-Host "`nðŸ§© VÃ©rification dâ€™intÃ©gritÃ© Ã©motionnelle interne..." -ForegroundColor Cyan

    $ModulesDir = Join-Path $RootDir "Modules"
    $Modules = @(
        @{ Name = "Athena.EmotionEngine"; Path = Join-Path $ModulesDir "Athena.EmotionEngine.psm1" },
        @{ Name = "Athena.SelfReflection"; Path = Join-Path $ModulesDir "Athena.SelfReflection.psm1" },
        @{ Name = "Athena.VisualSync"; Path = Join-Path $ModulesDir "Athena.VisualSync.psm1" },
        @{ Name = "Athena.Voice"; Path = Join-Path $ModulesDir "Athena.Voice.psm1" }
    )

    $results = @()
    foreach ($mod in $Modules) {
        $name = $mod.Name
        $path = $mod.Path
        if (Test-Path $path) {
            try {
                Import-Module $path -Force -ErrorAction SilentlyContinue | Out-Null
                if (Get-Module $name) {
                    Write-Host "âœ… $name actif" -ForegroundColor Green
                    $results += "[OK] $name actif"
                } else {
                    Write-Host "âš ï¸ $name inactif" -ForegroundColor Yellow
                    $results += "[WARN] $name inactif"
                }
            } catch {
                Write-Host "âŒ Erreur import $name" -ForegroundColor Red
                $results += "[ERROR] $name : $_"
            }
        } else {
            Write-Host "âŒ Module manquant : $name" -ForegroundColor Red
            $results += "[MISSING] $name absent"
        }
    }

    $ok = ($results | Where-Object { $_ -match "\[OK\]" }).Count
    $total = $results.Count
    $score = [math]::Round(($ok / [math]::Max($total,1)) * 100, 1)
    Add-Content -Path $IntegrityLog -Value ("[" + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") + "] Score de cohÃ©rence Ã©motionnelle : $score %")
    $results | ForEach-Object { Add-Content -Path $IntegrityLog -Value "    $_" }

    if ($score -eq 100) {
        Write-Host "ðŸ§˜ CohÃ©rence Ã©motionnelle parfaite." -ForegroundColor Green
    } elseif ($score -ge 70) {
        Write-Host "âš™ï¸ CohÃ©rence partielle â€“ certains modules manquent." -ForegroundColor Yellow
    } else {
        Write-Host "ðŸš¨ DÃ©sÃ©quilibre Ã©motionnel dÃ©tectÃ©." -ForegroundColor Red
    }
    Write-Host ""
}

# ====================================================================
# ðŸ§  Cycle principal dâ€™auto-rÃ©flexion amÃ©liorÃ©
# ====================================================================
function Invoke-AthenaSelfReflection {
    Write-Host "`nðŸªž DÃ©marrage du moteur dâ€™auto-rÃ©flexion dâ€™Athena..." -ForegroundColor Cyan

    try {
        # VÃ©rification intÃ©grÃ©e
        Test-EmotionIntegrity

        # Lecture et analyse
        $raw = Read-EmotionHistory
        $index = Compute-HarmonyIndex -RawData $raw
        $trend = Detect-EmotionTrends -RawData $raw
        $report = Generate-ReflectionReport -HarmonyIndex $index -Trend $trend
        Save-EmotionHistoryJSON -Report $report
        Invoke-AthenaSelfRegulation -HarmonyIndex $index

        # SynthÃ¨se finale
        Write-Host "ðŸ’« Ã‰motion actuelle : $(if ($index -ge 70) { 'Stable (SÃ©rÃ©nitÃ©)' } elseif ($index -ge 50) { 'FatiguÃ©e' } else { 'Tendue' })"
        Write-Host "âœ… Cycle dâ€™auto-rÃ©flexion terminÃ©. ($($report.ReflectionState))" -ForegroundColor Green
        Write-ReflectionLog "Cycle complet terminÃ© avec succÃ¨s."
    }
    catch {
        Write-Warning "âŒ Erreur lors du cycle dâ€™auto-rÃ©flexion : $_"
        Write-ReflectionLog "Erreur : $_"
    }
}

# ====================================================================
# ðŸ§ª Fonctions futures dÃ©jÃ  prÃ©parÃ©es (dÃ©sactivÃ©es)
# ====================================================================
<#
function Invoke-DeepEmotionReset { }
function Override-EmotionProfile { }
function Simulate-EmotionScenario { }
function Purge-EmotionHistory { }
function Force-AthenaHarmonyBoost { }
function Invoke-AutoSelfHealing { }
#>

# ====================================================================
# ðŸ”š Exportation
# ====================================================================
Export-ModuleMember -Function `
    Invoke-AthenaSelfReflection, `
    Test-EmotionIntegrity, `
    Get-HarmonyStatus, `
    Compute-HarmonyIndex, `
    Detect-EmotionTrends, `
    Read-EmotionHistory, `
    Generate-ReflectionReport, `
    Save-EmotionHistoryJSON, `
    Invoke-AthenaSelfRegulation, `
    Write-ReflectionLog

Write-Host "ðŸªž Module Athena.SelfReflection.psm1 chargÃ© (v2.0â€“SelfAdaptive)." -ForegroundColor Cyan
Write-ReflectionLog "Module chargÃ© (v2.0â€“SelfAdaptive)"


function Set-PermissionState {
    param([string]$FunctionName,[string]$State)
    $permFile = Join-Path (Join-Path $Root "Memory") "Permissions.json"
    if (!(Test-Path $permFile)) { @{} | ConvertTo-Json | Out-File $permFile -Encoding utf8 }
    try {
        $permissions = Get-Content $permFile -Raw | ConvertFrom-Json
        $permissions | Add-Member -NotePropertyName $FunctionName -NotePropertyValue $State -Force
        $permissions | ConvertTo-Json -Depth 3 | Out-File $permFile -Encoding utf8
        Write-Host "ðŸ” Permission mise Ã  jour : $FunctionName â†’ $State" -ForegroundColor Green
    } catch {
        Write-Warning "Erreur lors de la mise Ã  jour des permissions : $_"
    }
}
Export-ModuleMember -Function Set-PermissionState


