# =====================================================================
# ðŸ§  Athena.Learning.psm1 â€“ Phase 13 : Auto-Learning Adaptatif + Cockpit
# Version : v2.4-CockpitSync
# =====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$SummaryFile = Join-Path $MemoryDir "LearningSummary.json"
$LearningLog = Join-Path $MemoryDir "Learning.log"

function Write-LearningLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LearningLog -Value "[$t][$Level] $Msg"
    Write-Host "ðŸ§© $Msg"
}

function Initialize-Learning {
    Write-LearningLog "Initialisation du module Athena.Learning (v2.4-CockpitSync)..."
    foreach ($dep in @("Athena.SelfRepair","AutoPatch","Cockpit.Signal")) {
        $path = Join-Path (Join-Path $RootDir "Modules") "$dep.psm1"
        if (Test-Path $path) {
            Import-Module $path -Force -Global
            Write-LearningLog "âœ… DÃ©pendance chargÃ©e : $dep"
        } else {
            Write-LearningLog "âš ï¸ DÃ©pendance manquante : $dep" "WARN"
        }
    }
    if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null }
    Write-LearningLog "Moteur dâ€™apprentissage prÃªt."
}

function Analyze-AthenaLogs {
    Write-LearningLog "Lecture et analyse des logs (7 derniers jours)..."
    $files = Get-ChildItem -Path $LogsDir -Filter "*.log" -ErrorAction SilentlyContinue |
             Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }

    if (-not $files) { return @{data=@{};logs_scanned=0} }

    $modulesData = @{}; $totalLines = 0
    foreach ($f in $files) {
        $lines = Get-Content $f.FullName -ErrorAction SilentlyContinue
        $totalLines += (@($lines).Count)
        foreach ($l in $lines) {
            if ($l -match "Module (\S+)") {
                $m = $Matches[1] -replace ":", ""
                if (-not $modulesData.ContainsKey($m)) {
                    $modulesData[$m] = [ordered]@{repaired=0;errors=0;warns=0;stable=0}
                }
                if ($l -match "ERROR") { $modulesData[$m].errors++ }
                elseif ($l -match "WARN|âš ï¸") { $modulesData[$m].warns++ }
                elseif ($l -match "âœ…|stable|terminÃ©e") { $modulesData[$m].stable++ }
                elseif ($l -match "rÃ©parÃ©|recrÃ©Ã©") { $modulesData[$m].repaired++ }
            }
        }
    }

    foreach ($m in $modulesData.Keys) {
        $d=$modulesData[$m]
        $total=[math]::Max(1,$d.errors+$d.warns+$d.stable)
        $modulesData[$m].confidence=[math]::Round(1-(($d.errors+($d.warns*0.5))/$total),2)
    }

    Write-LearningLog "Analyse terminÃ©e sur $((@($modulesData).Count)) modules et $totalLines lignes."
    return @{data=$modulesData;logs_scanned=$totalLines}
}

function Save-LearningSummary {
    param([hashtable]$Analysis)
    $data=$Analysis.data; $lines=$Analysis.logs_scanned
    $anoms=if($data){($data.Values|Where-Object{$_.errors -gt 0}).Count}else{0}
    if(-not $anoms){$anoms=0}

    $summary=[ordered]@{
        date=(Get-Date).ToString("s")
        logs_scanned=$lines
        modules_analyzed=$data
        anomalies_detected=$anoms
        summary_text=if($anoms -eq 0){"Aucune anomalie dÃ©tectÃ©e sur $lines lignes. SystÃ¨me stable."}
                     else{"$anoms anomalie$([string]::Concat(($anoms -gt 1)?'s':'')) dÃ©tectÃ©e$(([string]::Concat(($anoms -gt 1)?'s':''))) sur $lines lignes."}
    }

    $summary|ConvertTo-Json -Depth 5|Set-Content -Path $SummaryFile -Encoding UTF8
    Write-LearningLog "ðŸ§  RÃ©sumÃ© sauvegardÃ© dans $SummaryFile"
    return $summary
}

function Report-LearningSummary {
    param([hashtable]$Summary)
    if(-not $Summary){return}
    $text=$Summary.summary_text
    Write-Host "`nðŸ’¬ $text`n"
    try{
        if(Get-Command Invoke-AthenaVoice -ErrorAction SilentlyContinue){
            Invoke-AthenaVoice -Text $text -Silent
        }
    }catch{}
}

function Invoke-AthenaLearning {
    Write-LearningLog "ðŸš€ Lancement du cycle Athena Auto-Learning (v2.4-CockpitSync)..."
    Initialize-Learning
    $a=Analyze-AthenaLogs
    $s=Save-LearningSummary -Analysis $a
    Report-LearningSummary -Summary $s

    # --- Notification visuelle cockpit ---
    if(Get-Command Notify-CockpitLearning -ErrorAction SilentlyContinue){
        Notify-CockpitLearning -Status "OK" -Anomalies $s.anomalies_detected -Lines $s.logs_scanned
    }

    Write-LearningLog "âœ… Cycle dâ€™apprentissage terminÃ©."
}

Export-ModuleMember -Function Invoke-AthenaLearning,Write-LearningLog,Initialize-Learning
Write-Host "ðŸ§  Module Athena.Learning chargÃ© (v2.4-CockpitSync)."




