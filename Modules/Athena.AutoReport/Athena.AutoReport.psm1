# ====================================================================
# ðŸŒ… Athena.AutoReport.psm1 â€” Rapport quotidien + push Cockpit (Phase 10)
# Version : 1.2-stable-final
# Auteur : Athena Engine
# Description :
#   GÃ©nÃ¨re un tableau de bord synthÃ©tique (JSON)
#   â†’ Historise les tendances
#   â†’ Pousse le rapport vers le Cockpit
#   â†’ Lit le rÃ©sumÃ© Ã  voix haute (si moteur vocal disponible)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --------------------------------------------------------------------
# âš™ï¸ Fonction principale
# --------------------------------------------------------------------
function Invoke-AthenaAutoReport {
    [CmdletBinding()]
    param(
        [switch]$PushToCockpit,
        [int]$LookbackDays = 7,
        [switch]$WithVoice
    )

    $ModuleDir   = Split-Path -Parent $PSCommandPath
    $RootDir     = Split-Path -Parent $ModuleDir
    $LogsDir     = Join-Path $RootDir 'Logs'
    $MemoryDir   = Join-Path $RootDir 'Memory'
    $HistoryDir  = Join-Path $MemoryDir 'History'

    if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null }
    if (!(Test-Path $HistoryDir)) { New-Item -ItemType Directory -Path $HistoryDir -Force | Out-Null }

    $dailyLog     = Join-Path $LogsDir 'AthenaDaily.log'
    $integrityLog = Join-Path $LogsDir 'AthenaIntegrity.log'
    $reportLog    = Join-Path $LogsDir 'AthenaReport.log'
    $dashFile     = Join-Path $MemoryDir 'AthenaDashboard.json'

    Write-Host "`nðŸŒ… GÃ©nÃ©ration du rapport visuel Athena (Phase 10)..." -ForegroundColor Cyan

    # ----------------------------------------------------------------
    # 1ï¸âƒ£ Extraction du score courant
    # ----------------------------------------------------------------
    $score = 0
    if (Test-Path $reportLog) {
        $match = Select-String -Path $reportLog -Pattern 'Score global\s*:\s*(\d+)%' -SimpleMatch:$false | Select-Object -Last 1
        if ($match -and $match.Matches.Groups[1].Value) {
            [void][int]::TryParse($match.Matches.Groups[1].Value, [ref]$score)
        }
    }

    # ----------------------------------------------------------------
    # 2ï¸âƒ£ Analyse des tendances
    # ----------------------------------------------------------------
    $scores = @()
    $cutDate = (Get-Date).AddDays(-$LookbackDays)

    if (Test-Path $reportLog) {
        $lines = Get-Content $reportLog -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match '^(?<date>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}).*Score global\s*:\s*(?<val>\d+)%') {
                $d = Get-Date $matches['date'] -ErrorAction SilentlyContinue
                if ($d -and $d -ge $cutDate) {
                    $v = 0
                    [void][int]::TryParse($matches['val'], [ref]$v)
                    $scores += [pscustomobject]@{ Date = $d; Value = $v }
                }
            }
        }
    }

    $trend = 'stable'
    if ((@($scores).Count) -ge 2) {
        $first = $scores | Sort-Object Date | Select-Object -First 1
        $last  = $scores | Sort-Object Date | Select-Object -Last 1
        if ($last.Value -gt $first.Value) { $trend = 'up' }
        elseif ($last.Value -lt $first.Value) { $trend = 'down' }
        Write-Host "ðŸ“Š Tendance des $((@($scores).Count)) derniers scores : $trend" -ForegroundColor Cyan
    }
    elseif ((@($scores).Count) -eq 1) {
        Write-Host "ðŸ“Š Un seul score trouvÃ© â€” tendance stable par dÃ©faut." -ForegroundColor DarkGray
    }
    else {
        Write-Host "âš ï¸ Aucun score trouvÃ© pour les $LookbackDays derniers jours." -ForegroundColor Yellow
    }

    # ----------------------------------------------------------------
    # 3ï¸âƒ£ Ã‰tat des modules clÃ©s
    # ----------------------------------------------------------------
    $modules = @(
        'Athena.Supervisor',
        'Athena.Validator',
        'Athena.AutoCycle',
        'Athena.Archive',
        'Athena.AlertBackup',
        'Athena.History',
        'Athena.SelfRepair'
    )

    $modsState = @{}
    foreach ($m in $modules) {
        $path   = Join-Path (Join-Path $RootDir 'Modules') ("$m.psm1")
        $exists = Test-Path $path
        $loaded = $false
        if ($exists) {
            try { Import-Module $path -Force -ErrorAction Stop; $loaded = $true } catch { $loaded = $false }
        }
        $modsState[$m] = @{ exists = $exists; loaded = $loaded }
    }

    # ----------------------------------------------------------------
    # 4ï¸âƒ£ GÃ©nÃ©ration du Dashboard JSON
    # ----------------------------------------------------------------
    $payload = [ordered]@{
        generated_at  = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        score         = $score
        trend         = $trend
        lookback_days = $LookbackDays
        modules       = $modsState
        sources       = @{
            AthenaDaily     = (Test-Path $dailyLog)
            AthenaIntegrity = (Test-Path $integrityLog)
            AthenaReport    = (Test-Path $reportLog)
        }
    }

    try {
        $json = $payload | ConvertTo-Json -Depth 6 -ErrorAction Stop
        Set-Content -Path $dashFile -Value $json -Encoding UTF8
        Write-Host "ðŸŒ… Dashboard Ã©crit : $dashFile" -ForegroundColor Green

        $hist = Join-Path $HistoryDir ("AthenaDashboard_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.json')
        Copy-Item $dashFile $hist -Force
        Write-Host "ðŸ“‚ Copie historique crÃ©Ã©e : $hist" -ForegroundColor DarkGray
    }
    catch {
        Write-Warning "âŒ Erreur lors de la gÃ©nÃ©ration du dashboard : $_"
    }

    # ----------------------------------------------------------------
    # 5ï¸âƒ£ Envoi vers le Cockpit
    # ----------------------------------------------------------------
    if ($PushToCockpit) {
        try {
            $cockpitMod = Join-Path (Join-Path $RootDir 'Modules') 'Cockpit.Signal.psm1'
            Import-Module $cockpitMod -Force -ErrorAction Stop
            Update-CockpitFromDashboard -DashboardPath $dashFile
            Write-Host "ðŸ“¡ Dashboard transmis au Cockpit avec succÃ¨s." -ForegroundColor Green
        }
        catch {
            Write-Warning "âš ï¸ Cockpit.Signal indisponible â€” le cockpit pourra lire directement $dashFile."
        }
    }

    # ----------------------------------------------------------------
    # 6ï¸âƒ£ RÃ©sumÃ© vocal optionnel
    # ----------------------------------------------------------------
    if ($WithVoice) {
        try {
            $msg = switch ($trend) {
                'up'     { "Athena a progressÃ©. Le score global est de $score pour cent, en hausse." }
                'down'   { "Athena a ralenti. Le score global est de $score pour cent, en baisse." }
                default  { "Athena est stable. Le score global reste Ã  $score pour cent." }
            }
            Write-Host "ðŸ”Š $msg" -ForegroundColor Magenta
            if (Get-Command -Name Invoke-AthenaVoice -ErrorAction SilentlyContinue) {
                Invoke-AthenaVoice -Text $msg
            }
        }
        catch {
            Write-Warning "âš ï¸ Lecture vocale impossible : $_"
        }
    }
}

# ----------------------------------------------------------------
# âœ… Export aprÃ¨s dÃ©finition complÃ¨te
# ----------------------------------------------------------------
Export-ModuleMember -Function Invoke-AthenaAutoReport




