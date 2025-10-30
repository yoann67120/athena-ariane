# ====================================================================
# ðŸ§± Athena.DefenseMatrix.psm1 â€“ v1.0-OmniShield
# Description : DÃ©tection, analyse et dÃ©fense adaptative du systÃ¨me
# Auteur      : Ariane V4 / Athena Engine
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --------------------------------------------------------------------
# ðŸ“ Initialisation des chemins
# --------------------------------------------------------------------
$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $ProjectDir "Logs"
$MemoryDir  = Join-Path $ProjectDir "Memory"

foreach ($d in @($LogsDir,$MemoryDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$DefenseLog  = Join-Path $LogsDir "AthenaDefense.log"
$SecurityLog = Join-Path $MemoryDir "SecurityLog.json"
$SnapshotFile = Join-Path $MemoryDir "IntegritySnapshot.json"
$RulesFile   = Join-Path $MemoryDir "AutoDefenseRules.json"

# --------------------------------------------------------------------
# âš™ï¸ Utilitaires
# --------------------------------------------------------------------
function Compute-FileHash {
    param([string]$Path)
    if (Test-Path $Path) {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    } else { return $null }
}

# --------------------------------------------------------------------
# ðŸ” Scan de tous les modules
# --------------------------------------------------------------------
function Scan-DefenseMatrix {
    param([string]$Path = (Join-Path $ProjectDir "Modules"))
    $mods = Get-ChildItem -Path $Path -Filter *.psm1 -File -Recurse -ErrorAction SilentlyContinue
    $report = foreach ($m in $mods) {
        [pscustomobject]@{
            Name  = $m.Name
            Path  = $m.FullName
            Hash  = Compute-FileHash $m.FullName
            Size  = $m.Length
            LastWrite = $m.LastWriteTime
        }
    }
    return $report
}

# --------------------------------------------------------------------
# ðŸ§  DÃ©tection des anomalies
# --------------------------------------------------------------------
function Detect-Anomalies {
    param([object]$Snapshot)
    if (-not $Snapshot -and (Test-Path $SnapshotFile)) {
        $Snapshot = Get-Content $SnapshotFile -Raw | ConvertFrom-Json
    }
    $current = Scan-DefenseMatrix
    $added = $current | Where-Object { ($Snapshot.Path -notcontains $_.Path) }
    $deleted = $Snapshot | Where-Object { ($current.Path -notcontains $_.Path) }
    $modified = foreach ($c in $current) {
        $s = $Snapshot | Where-Object { $_.Path -eq $c.Path }
        if ($s -and $s.Hash -ne $c.Hash) { $c }
    }
    return [pscustomobject]@{
        Added    = $added
        Deleted  = $deleted
        Modified = $modified
        Count    = ($added.Count + $deleted.Count + $modified.Count)
    }
}

# --------------------------------------------------------------------
# ðŸ“Š Ã‰valuation du niveau de menace
# --------------------------------------------------------------------
function Assess-ThreatLevel {
    param([object]$Anomalies)
    $count = $Anomalies.Count
    if ($count -eq 0) { return 0 }
    elseif ($count -le 2) { return 1 }
    elseif ($count -le 5) { return 2 }
    else { return 3 }
}

function Compute-TrustScore {
    param([object]$Anomalies)
    $total = [math]::Max(1, ($Anomalies.Added.Count + $Anomalies.Deleted.Count + $Anomalies.Modified.Count))
    $score = 100 - [math]::Min(100, $total * 10)
    return $score
}

# --------------------------------------------------------------------
# ðŸ§© RÃ©action adaptative (non destructive)
# --------------------------------------------------------------------
function React-ToThreat {
    param([int]$Level,[object]$Anomalies)
    Add-Content -Path $DefenseLog -Value "[$(Get-Date -Format u)] Niveau menace : $Level (Anomalies : $($Anomalies.Count))"

    switch ($Level) {
        0 { Write-Host "ðŸŸ¢ Aucun problÃ¨me dÃ©tectÃ©." -ForegroundColor Green }
        1 {
            Write-Host "ðŸŸ¡ Anomalies mineures dÃ©tectÃ©es â€“ modules surveillÃ©s." -ForegroundColor Yellow
        }
        2 {
            Write-Host "ðŸŸ  Menace modÃ©rÃ©e â€“ application de verrouillage prÃ©ventif." -ForegroundColor DarkYellow
            if (Get-Command Lock-CriticalModules -ErrorAction SilentlyContinue) {
                Lock-CriticalModules -Modules @("Core.psm1","LocalModel.psm1") | Out-Null
            }
        }
        3 {
            Write-Host "ðŸ”´ Menace critique â€“ passage en mode Isolation." -ForegroundColor Red
            if (Get-Command Set-SecurityLevel -ErrorAction SilentlyContinue) {
                Set-SecurityLevel -Level 2 -Reason "Menace critique dÃ©tectÃ©e"
            }
        }
    }
}

# --------------------------------------------------------------------
# ðŸ“œ Rapport et journalisation
# --------------------------------------------------------------------
function Generate-SecurityReport {
    param([object]$Anomalies,[int]$Threat,[int]$Trust)

    try {
        # --- RÃ©initialisation totale du fichier (supprime tout fichier "null" ou vide) ---
        if (Test-Path $SecurityLog) {
            $raw = [System.IO.File]::ReadAllText($SecurityLog)
            if ([string]::IsNullOrWhiteSpace($raw) -or $raw -eq 'null') {
                [System.IO.File]::Delete($SecurityLog)
            }
        }

        if (-not (Test-Path $SecurityLog)) {
            [System.IO.File]::WriteAllText($SecurityLog, '[]', [System.Text.Encoding]::UTF8)
        }

        # --- SÃ©curisation des propriÃ©tÃ©s dâ€™anomalies ---
        if (-not $Anomalies) { $Anomalies = @{} }
        if (-not $Anomalies.PSObject.Properties['Added'])    { $Anomalies | Add-Member -NotePropertyName 'Added'    -NotePropertyValue @() }
        if (-not $Anomalies.PSObject.Properties['Deleted'])  { $Anomalies | Add-Member -NotePropertyName 'Deleted'  -NotePropertyValue @() }
        if (-not $Anomalies.PSObject.Properties['Modified']) { $Anomalies | Add-Member -NotePropertyName 'Modified' -NotePropertyValue @() }

        # --- Construction de l'entrÃ©e ---
        $entry = [pscustomobject]@{
            Date     = (Get-Date)
            Threat   = $Threat
            Trust    = $Trust
            Added    = ($Anomalies.Added | ForEach-Object { $_.Name })
            Deleted  = ($Anomalies.Deleted | ForEach-Object { $_.Name })
            Modified = ($Anomalies.Modified | ForEach-Object { $_.Name })
        }

        # --- Lecture et mise Ã  jour du JSON ---
        $content = [System.IO.File]::ReadAllText($SecurityLog)
        try { $json = if ($content) { $content | ConvertFrom-Json } else { @() } }
        catch { $json = @() }
        if (-not ($json -is [System.Collections.IEnumerable])) { $json = @() }
        $json += $entry

        # --- Ã‰criture atomique ---
        $jsonString = ($json | ConvertTo-Json -Depth 6)
        [System.IO.File]::WriteAllText($SecurityLog, $jsonString, [System.Text.Encoding]::UTF8)

        Add-Content -Path $DefenseLog -Value "[$(Get-Date -Format u)] Rapport gÃ©nÃ©rÃ© : menace=$Threat | confiance=$Trust | anomalies=$($Anomalies.Count)"
        Write-Host "ðŸ“Š Rapport de sÃ©curitÃ© mis Ã  jour (Trust=$Trust%)." -ForegroundColor Cyan
    }
    catch {
        Write-Warning "âš ï¸ Erreur critique dans Generate-SecurityReport : $($_.Exception.Message)"
    }
}

# --------------------------------------------------------------------
# ðŸ¤– Apprentissage simple (adaptatif)
# --------------------------------------------------------------------
function Update-AutoDefenseRules {
    param([int]$Threat,[object]$Anomalies)
    $rules = @{}
    if (Test-Path $RulesFile) {
        try { $rules = Get-Content $RulesFile -Raw | ConvertFrom-Json } catch { $rules=@{} }
    }
    $key = "ThreatLevel$Threat"
    if (-not $rules.$key) { $rules.$key = @{ Count = 0; LastSeen = (Get-Date) } }
    $rules.$key.Count++
    $rules.$key.LastSeen = (Get-Date)
    $rules | ConvertTo-Json -Depth 6 | Set-Content $RulesFile -Encoding utf8
    Add-Content -Path $DefenseLog -Value "[$(Get-Date -Format u)] AutoDefenseRules mis Ã  jour pour niveau $Threat"
}

# --------------------------------------------------------------------
# ðŸš€ Cycle principal â€“ appelÃ© par SafeOps
# --------------------------------------------------------------------
function Invoke-AthenaDefenseMatrix {
    param([object]$Snapshot)

    Write-Host "`nðŸ§  Lancement du moteur DefenseMatrix..." -ForegroundColor Cyan
    $snap = if ($Snapshot) { $Snapshot } elseif (Test-Path $SnapshotFile) {
        Get-Content $SnapshotFile -Raw | ConvertFrom-Json
    } else { @() }

    $anomalies = Detect-Anomalies -Snapshot $snap
    $threat = Assess-ThreatLevel -Anomalies $anomalies
    $trust  = Compute-TrustScore -Anomalies $anomalies

    React-ToThreat -Level $threat -Anomalies $anomalies
    Generate-SecurityReport -Anomalies $anomalies -Threat $threat -Trust $trust
    Update-AutoDefenseRules -Threat $threat -Anomalies $anomalies

    Write-Host "ðŸ§© DefenseMatrix terminÃ© : menace=$threat | confiance=$trust% | anomalies=$($anomalies.Count)" -ForegroundColor Green
}

# --------------------------------------------------------------------
# ðŸ“¦ Export des fonctions publiques
# --------------------------------------------------------------------
Export-ModuleMember -Function `
    Compute-FileHash, Scan-DefenseMatrix, Detect-Anomalies, Assess-ThreatLevel, `
    Compute-TrustScore, React-ToThreat, Generate-SecurityReport, `
    Update-AutoDefenseRules, Invoke-AthenaDefenseMatrix

Write-Host "âœ… Module Athena.DefenseMatrix chargÃ© (v1.0-OmniShield â€“ analyse adaptative active)."



