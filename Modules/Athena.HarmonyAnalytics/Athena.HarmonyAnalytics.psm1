# ====================================================================
# ðŸ“Š Athena.HarmonyAnalytics.psm1 â€“ Calculs, tendances et rapports
# Version : v1.0.3-Analytics-Stable (Correctif final op_Addition + SÃ©curisation renforcÃ©e)
# Auteur  : Athena Core Engine / Ariane V4
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$MemoryDir = Join-Path $RootDir "Memory"
$LogsDir   = Join-Path $RootDir "Logs"
$LogFile   = Join-Path $LogsDir "AthenaHarmonyAnalytics.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-AnalyticsLog {
    param([string]$Message,[string]$Level="INFO")
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level] $Message"
}

# ðŸ”¹ Calcul de mÃ©triques dÃ©taillÃ©es
function Compute-HarmonyMetrics {
    param([array]$Data)
    if (-not $Data -or $Data.Count -eq 0) { return $null }

    $avg = ($Data | Measure-Object -Property Indice -Average).Average
    $sum = 0
    foreach ($d in $Data) {
        $sum += [math]::Pow(($d.Indice - $avg), 2)
    }
    $std = if ($Data.Count -gt 1) { [math]::Sqrt($sum / ($Data.Count - 1)) } else { 0 }

    return [PSCustomObject]@{
        Moyenne   = [math]::Round($avg,2)
        EcartType = [math]::Round($std,2)
        Min       = ($Data.Indice | Measure-Object -Minimum).Minimum
        Max       = ($Data.Indice | Measure-Object -Maximum).Maximum
    }
}

# ðŸ”¹ AgrÃ©gation journaliÃ¨re
function Aggregate-DailyStats {
    $file = Join-Path $MemoryDir "HarmonyProfile.json"
    if (!(Test-Path $file)) {
        Write-AnalyticsLog "Aucun fichier HarmonyProfile.json trouvÃ©."
        return @()
    }

    $data = Get-Content $file -Raw | ConvertFrom-Json
    if (-not $data) { return @() }

    $group = $data | Group-Object { ([datetime]$_.Timestamp).Date }

    # --- Initialisation sÃ©curisÃ©e ---
    $result = @()
    if ($null -eq $group) { return @() }

    foreach ($g in $group) {
        $metrics = Compute-HarmonyMetrics -Data $g.Group
        if ($metrics) {
            $entry = [PSCustomObject]@{
                Date      = $g.Name
                Moyenne   = $metrics.Moyenne
                EcartType = $metrics.EcartType
                Min       = $metrics.Min
                Max       = $metrics.Max
            }
            # --- Correctif op_Addition ---
            if (-not ($result -is [System.Collections.IEnumerable]) -or ($result -is [string])) {
                $result = @($result)
            }
            $result += $entry
        }
    }

    Write-AnalyticsLog "AgrÃ©gation journaliÃ¨re : $($result.Count) jours traitÃ©s."
    return $result
}

# ðŸ”¹ PrÃ©diction simple de tendance
function Predict-HarmonyTrend {
    $stats = Aggregate-DailyStats
    if (-not $stats -or $stats.Count -lt 2) { return "Stable" }

    $trend = $stats[-1].Moyenne - $stats[-2].Moyenne
    if ($trend -gt 2)      { return "AmÃ©lioration" }
    elseif ($trend -lt -2) { return "DÃ©gradation" }
    else                   { return "Stable" }
}

# ðŸ”¹ Export de rapport synthÃ©tique
function Export-HarmonyReport {
    $reportFile = Join-Path $MemoryDir "HarmonyReport_$(Get-Date -Format yyyyMMdd).json"
    $data   = Aggregate-DailyStats
    $trend  = Predict-HarmonyTrend

    $report = [PSCustomObject]@{
        GÃ©nÃ©rÃ©Le = (Get-Date)
        Tendance = $trend
        Stats    = $data
    }

    try {
        $report | ConvertTo-Json -Depth 4 | Out-File $reportFile -Encoding utf8
        Write-AnalyticsLog "Rapport exportÃ© : $reportFile"
    }
    catch {
        Write-AnalyticsLog "Erreur export rapport : $_" "ERROR"
    }

    return $reportFile
}

# ðŸ”¹ Visualisation locale (ASCII)
function Visualize-HarmonyHistory {
    $data = Aggregate-DailyStats
    if (-not $data -or $data.Count -eq 0) {
        Write-Host "Aucune donnÃ©e d'historique disponible."
        return
    }

    Write-Host "ðŸ“ˆ Historique de lâ€™harmonie :"
    foreach ($d in $data) {
        $bar = "â–ˆ" * [math]::Round($d.Moyenne / 2)
        Write-Host ("{0:dd/MM} | {1,6:N1}% | {2}" -f $d.Date, $d.Moyenne, $bar)
    }
}

Export-ModuleMember -Function Compute-HarmonyMetrics,Aggregate-DailyStats,Predict-HarmonyTrend,Export-HarmonyReport,Visualize-HarmonyHistory
Write-Host "ðŸ“Š Module Athena.HarmonyAnalytics.psm1 chargÃ© (v1.0.3-Analytics-Stable)." -ForegroundColor Cyan



