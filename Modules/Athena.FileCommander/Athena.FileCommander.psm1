# ====================================================================
# Athena.FileCommander.psm1  v1.0-DirectConsole
# Canal texte direct avec Athena pour diagnostic et auto-rÃ©paration
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $RootDir
$Modules   = Join-Path $RootDir "Modules"
$LogsDir   = Join-Path $RootDir "Logs"
$Report    = Join-Path $LogsDir "FileCommander_Report.txt"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-Report {
    param([string]$Msg,[string]$Level="INFO")
    $time=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line="[$time][$Level] $Msg"
    Add-Content -Path $Report -Value $line
    Write-Host $line
}

function Invoke-FileScan {
    Write-Report "=== DÃ‰MARRAGE DU SCAN COMPLET ==="

    $errors=@()
    $files = Get-ChildItem -Path $RootDir -Recurse -Include *.ps1,*.psm1,*.json,*.txt -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        try {
            if ($f.Extension -match "psm1|ps1") {
                $content = Get-Content $f.FullName -Raw
                [void][System.Management.Automation.Language.Parser]::ParseInput($content,[ref]$null,[ref]$null)
            }
            elseif ($f.Extension -eq ".json") {
                try { $null = $f | Get-Content -Raw | ConvertFrom-Json } catch {
                    $errors += $f.FullName
                    Write-Report "âŒ JSON invalide : $($f.FullName)"
                }
            }
        } catch {
            $errors += $f.FullName
            Write-Report "âš ï¸ Erreur dans $($f.FullName) : $($_.Exception.Message)"
        }
    }

    Write-Report "Scan terminÃ© : $($files.Count) fichiers analysÃ©s, $($errors.Count) anomalies."
    return $errors
}

function Invoke-FileRepair {
    param([string[]]$Files)
    foreach ($f in $Files) {
        try {
            $backup = "$($f).bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item $f $backup -Force
            $content = Get-Content $f -Raw -ErrorAction Stop

            if ($f -like "*.json") {
                $content = $content -replace ",\s*}", "}" -replace ",\s*]", "]"
                $null = $content | ConvertFrom-Json -ErrorAction Stop
                $content | Out-File $f -Encoding utf8
                Write-Report "âœ… RÃ©parÃ© : $f"
            }
        } catch {
            Write-Report "âŒ Ã‰chec de la rÃ©paration : $f | $($_.Exception.Message)"
        }
    }
}

function Start-FileCommander {
    Clear-Host
    Write-Host "===================================================="
    Write-Host "ðŸ§  ATHENA â€“ CANAL DIRECT | MODULE FILE COMMANDER"
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "Tape 'scan' pour lancer lâ€™analyse complÃ¨te."
    Write-Host "Tape 'repair' pour corriger les fichiers dÃ©fectueux."
    Write-Host "Tape 'exit' pour quitter." -ForegroundColor Yellow
    Write-Host ""

    $issues = @()
    while ($true) {
        $cmd = Read-Host "â†’ Commande"
        switch -Regex ($cmd.ToLower()) {
            '^scan$' {
                $issues = Invoke-FileScan
                if ($issues.Count -eq 0) {
                    Write-Host "ðŸŽ¯ Aucun problÃ¨me dÃ©tectÃ©." -ForegroundColor Green
                } else {
                    Write-Host "âš ï¸ $($issues.Count) fichiers Ã  rÃ©parer." -ForegroundColor Yellow
                }
            }
            '^repair$' {
                if ($issues.Count -eq 0) {
                    Write-Host "Aucune liste dâ€™erreurs chargÃ©e. Lance dâ€™abord 'scan'." -ForegroundColor Yellow
                } else {
                    Invoke-FileRepair -Files $issues
                }
            }
            '^exit$' { Write-Host "ðŸ”š Fermeture du canal."; break }
            default  { Write-Host "Commande inconnue. Utilise : scan | repair | exit" -ForegroundColor DarkGray }
        }
    }
}

Export-ModuleMember -Function Start-FileCommander
Write-Host "Module Athena.FileCommander.psm1 chargÃ© (v1.0-DirectConsole)." -ForegroundColor Cyan


