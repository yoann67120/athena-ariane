# ====================================================================
# âš™ï¸ Athena.AutoOptimize.psm1 â€“ Optimisation automatique du systÃ¨me
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir  = Split-Path -Parent $PSScriptRoot
$LogsDir  = Join-Path $RootDir "Logs"
$LogFile  = Join-Path $LogsDir "AthenaOptimize.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-AthenaOptimizeLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t] $Msg"
}

function Invoke-AthenaOptimize {
    Write-Host "ðŸ§¹ Lancement de l'optimisation automatique..." -ForegroundColor Cyan
    Write-AthenaOptimizeLog "=== Nouvelle session d'optimisation ==="

    # 1ï¸âƒ£ VÃ©rifier la mÃ©moire libre et le CPU
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $mem = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
    Write-AthenaOptimizeLog "CPU: $([math]::Round($cpu,2))% | RAM libre: $mem MB"

    # 2ï¸âƒ£ Nettoyage des fichiers temporaires
    $tempPath = [IO.Path]::GetTempPath()
    Get-ChildItem -Path $tempPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-AthenaOptimizeLog "ðŸ§½ Nettoyage du dossier temporaire terminÃ©."

    # 3ï¸âƒ£ Compactage des logs trop gros
    Get-ChildItem $LogsDir -Filter *.log | Where-Object { $_.Length -gt 5MB } | ForEach-Object {
        $zip = "$($_.FullName).zip"
        Compress-Archive -Path $_.FullName -DestinationPath $zip -Force
        Remove-Item $_.FullName -Force
        Write-AthenaOptimizeLog "ðŸ—œï¸ Log compressÃ© : $($_.Name)"
    }

    # 4ï¸âƒ£ Optimisation du garbage collector
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Write-AthenaOptimizeLog "â™»ï¸ Garbage collector exÃ©cutÃ©."

    Write-Host "âœ… Optimisation terminÃ©e." -ForegroundColor Green
    Write-AthenaOptimizeLog "âœ… Optimisation terminÃ©e."
}

Export-ModuleMember -Function Invoke-AthenaOptimize




