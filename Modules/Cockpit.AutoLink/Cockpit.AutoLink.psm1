# =====================================================================
# ðŸŽ›ï¸ Cockpit.AutoLink.psm1 â€“ Liaison cockpit â†” Athena
# Version : v1.0-stable
# =====================================================================
# Objectif :
#   - Relier le Cockpit K2000 Ã  lâ€™Ã©tat cognitif dâ€™Athena
#   - Afficher Score, Mode IA, CPU/RAM et statut systÃ¨me
#   - Colorer dynamiquement les barres du Cockpit selon lâ€™Ã©tat
# =====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Dossiers principaux ---
$ModuleDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleDir
$MemoryDir   = Join-Path $RootDir "Memory"
$LogsDir     = Join-Path $RootDir "Logs"
$ReportFile  = Join-Path $MemoryDir "GlobalReport.json"
$CockpitLog  = Join-Path $LogsDir "CockpitLink.log"

# --------------------------------------------------------------------
function Write-CockpitLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "[$t][$Level] $Msg"
    Add-Content -Path $CockpitLog -Value $entry
    Write-Host "ðŸŽ›ï¸ $Msg"
}

# --------------------------------------------------------------------
function Get-CockpitColor {
    param([double]$Score)
    switch ($Score) {
        {$_ -ge 80} { return "Green" }
        {$_ -ge 60} { return "Yellow" }
        default     { return "Red" }
    }
}

# --------------------------------------------------------------------
function Invoke-CockpitAutoLink {
    Write-CockpitLog "ðŸ”„ Synchronisation Cockpit â†” Athena en cours..."

    if (-not (Test-Path $ReportFile)) {
        Write-CockpitLog "âš ï¸ Aucun rapport global trouvÃ© ($ReportFile)." "WARN"
        return
    }

    try {
        $data = Get-Content $ReportFile -Raw | ConvertFrom-Json
    } catch {
        Write-CockpitLog "âŒ Erreur lecture du rapport global : $_" "ERROR"
        return
    }

    $score = [double]($data.Score_Global)
    $color = Get-CockpitColor -Score $score
    $cpu   = if ($data.CPU_Load) { "$($data.CPU_Load)%" } else { "N/A" }
    $ram   = if ($data.RAM_Free) { "$([math]::Round($data.RAM_Free,2)) MB" } else { "N/A" }
    $mode  = $data.IA_Mode
    $rec   = $data.Recommandation

    # --- Mise Ã  jour visuelle du cockpit (si modules UI disponibles) ---
    if (Get-Command -Name Update-CockpitStatus -ErrorAction SilentlyContinue) {
        Update-CockpitStatus -CPU $cpu -RAM $ram -Mode $mode -Score $score -Color $color -Message $rec
        Write-CockpitLog "âœ… Cockpit mis Ã  jour via fonction UI (Update-CockpitStatus)."
    } else {
        # Mode texte de secours
        Write-Host "`n================ COCKPIT LINK ================" -ForegroundColor $color
        Write-Host "ðŸ§  Mode IA : $mode"
        Write-Host "ðŸ’» CPU : $cpu | RAM : $ram"
        Write-Host "ðŸ Score global : $score%"
        Write-Host "ðŸ§­ Recommandation : $rec"
        Write-Host "==============================================`n"
        Write-CockpitLog "â„¹ï¸ Affichage texte alternatif effectuÃ© (aucune UI dÃ©tectÃ©e)."
    }

    # --- Journalisation du lien ---
    $logEntry = [ordered]@{
        Timestamp = (Get-Date).ToString("s")
        Score     = $score
        Mode      = $mode
        CPU       = $cpu
        RAM       = $ram
        Status    = $rec
    }
    $logEntry | ConvertTo-Json -Depth 4 | Add-Content -Path $CockpitLog -Encoding UTF8

    Write-CockpitLog "ðŸŽ¯ Liaison Cockpit â†” Athena terminÃ©e."
}

Export-ModuleMember -Function Invoke-CockpitAutoLink, Write-CockpitLog
Write-Host "ðŸŽ›ï¸ Module Cockpit.AutoLink chargÃ© (v1.0-stable)."



