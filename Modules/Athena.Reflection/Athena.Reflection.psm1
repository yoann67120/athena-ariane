# ====================================================================
# ðŸªž Athena.Reflection.psm1 (v1.1-Reflexive-Stable)
# Objectif : Analyse rÃ©flexive des performances et comportements dâ€™Athena
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

$ModuleRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ModuleRoot
$LogsDir     = Join-Path $ProjectRoot 'Logs'
$MemoryDir   = Join-Path $ProjectRoot 'Memory'

$DailyLog       = Join-Path $LogsDir 'AthenaDaily.log'
$SelfLog        = Join-Path $LogsDir 'SelfEvolution.log'
$MemoryLog      = Join-Path $LogsDir 'AthenaMemory.log'
$ReflectionLog  = Join-Path $LogsDir 'AthenaReflection.log'
$ReflectionFile = Join-Path $MemoryDir 'ReflectionSummary.json'

foreach ($d in @($LogsDir, $MemoryDir)) { if (!(Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null } }

# --------------------------------------------------------------------
function Get-RecentLogs {
    $sources = @($DailyLog, $SelfLog, $MemoryLog)
    $lines = @()
    foreach ($src in $sources) {
        if (Test-Path $src) {
            $content = Get-Content $src -Tail 500 -ErrorAction SilentlyContinue
            if ($content) { $lines += $content }
        }
    }
    return $lines
}

# --------------------------------------------------------------------
function Analyze-Performance {
    param([string[]]$Lines)

    if (-not $Lines -or $Lines.Count -eq 0) {
        return [ordered]@{ Success=0; Errors=0; Warnings=0; Rate=0; Modules=@() }
    }

    $stats = [ordered]@{
        Success = ($Lines | Where-Object { $_ -match 'âœ…|succÃ¨s|rÃ©ussi' }).Count
        Errors  = ($Lines | Where-Object { $_ -match 'âš ï¸|erreur|Ã©chec' }).Count
        Warnings = ($Lines | Where-Object { $_ -match 'warning|alerte' }).Count
        Modules = ($Lines | Where-Object { $_ -match 'Athena\.|Cockpit\.|AutoPatch' }) |
            ForEach-Object { if ($_ -match '([A-Za-z]+\.[A-Za-z]+)') { $Matches[1] } } |
            Group-Object | Sort-Object Count -Descending | Select-Object -First 5
    }

    $stats.TotalLines = $Lines.Count
    $stats.Rate = if ($stats.TotalLines -gt 0) {
        [math]::Round(($stats.Success / $stats.TotalLines) * 100, 2)
    } else { 0 }

    return $stats
}

# --------------------------------------------------------------------
function Generate-ReflectionText {
    param([hashtable]$Stats)

    $taux = $Stats.Rate
    $texte = @()
    $texte += "ðŸ§  RÃ©flexion dâ€™Athena sur le dernier cycle :"
    $texte += "Taux de rÃ©ussite : $taux% | Erreurs : $($Stats.Errors) | Avertissements : $($Stats.Warnings)"

    if ($taux -ge 85) {
        $texte += "Athena se perÃ§oit en Ã©quilibre cognitif et Ã©motionnel stable."
    } elseif ($taux -ge 60) {
        $texte += "Athena remarque quelques irrÃ©gularitÃ©s et envisage une rÃ©gulation adaptative."
    } else {
        $texte += "Athena perÃ§oit une baisse de cohÃ©rence et prÃ©voit un cycle de recalibrage complet."
    }

    if ($Stats.Modules.Count -gt 0) {
        $texte += "Modules les plus sollicitÃ©s :"
        foreach ($m in $Stats.Modules) { $texte += " - $($m.Name) ($($m.Count)x)" }
    }

    $texte += "Conclusion : progression continue observÃ©e malgrÃ© les fluctuations."
    return ($texte -join "`n")
}

# --------------------------------------------------------------------
function Save-Reflection {
    param([string]$Text, [hashtable]$Stats)

    $entry = [PSCustomObject]@{
        Date = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Stats = $Stats
        Reflection = $Text
    }

    $data = @()
    if (Test-Path $ReflectionFile) {
        try { $data = Get-Content $ReflectionFile -Raw | ConvertFrom-Json } catch {}
    }
    $data += $entry
    $data | ConvertTo-Json -Depth 4 | Out-File $ReflectionFile -Encoding utf8

    Add-Content -Path $ReflectionLog -Value "===== RÃ©flexion $(Get-Date -Format u) ====="
    Add-Content -Path $ReflectionLog -Value $Text
    Add-Content -Path $ReflectionLog -Value "============================================================`n"
}

# --------------------------------------------------------------------
function Invoke-AthenaReflection {
    Write-Host "`nðŸªž Phase 17.5 â€“ RÃ©flexion cognitive..." -ForegroundColor Cyan
    $lines = Get-RecentLogs
    if (-not $lines -or $lines.Count -eq 0) {
        Write-Warning "âš ï¸ Aucun log Ã  analyser."
        return
    }
    $stats = Analyze-Performance -Lines $lines
    $text = Generate-ReflectionText -Stats $stats
    Save-Reflection -Text $text -Stats $stats
    Write-Host "âœ… RÃ©flexion cognitive enregistrÃ©e." -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-AthenaReflection
Write-Host "ðŸªž Module Athena.Reflection.psm1 chargÃ© (v1.1-Reflexive-Stable)." -ForegroundColor Cyan




