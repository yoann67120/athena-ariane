# ====================================================================
# ðŸ”Ž Athena.GPTScanner.psm1
# Version : v1.3 - Scan intelligent des modules Ariane V4
# Auteur  : Yoann Rousselle / Athena Core
# RÃ´le   : Localise la racine ArianeV4, scanne les modules, gÃ©nÃ¨re un rapport JSON
# ====================================================================

function Invoke-GPTModuleScan {
    # ðŸ” Recherche intelligente de la racine ArianeV4
    $current = (Get-Location).Path
    while ($current -ne [System.IO.Path]::GetPathRoot($current)) {
        if ((Test-Path (Join-Path $current "Modules")) -and
            (Test-Path (Join-Path $current "Memory")) -and
            (Test-Path (Join-Path $current "Logs"))) {
            break
        }
        $current = Split-Path $current -Parent
    }

    if (-not (Test-Path (Join-Path $current "Modules"))) {
        Write-Host "âŒ Impossible de localiser le dossier ArianeV4 (Modules/Memory/Logs manquants)"
        return
    }

    $modulesPath = Join-Path $current "Modules"
    $memoryPath  = Join-Path $current "Memory"
    $logPath     = Join-Path $current "Logs"
    $scanFile    = Join-Path $memoryPath "GPT_Scan.json"
    $logFile     = Join-Path $logPath "Athena_GPT_Autonomy.log"

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $results = @()

    Get-ChildItem -Path $modulesPath -Filter "*.psm1" | ForEach-Object {
        $file = $_
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction Stop
            $lines = $content.Split("`n").Count
            $size = ($file.Length / 1KB).ToString("F1") + " KB"

            $results += [PSCustomObject]@{
                Name       = $file.Name
                Path       = $file.FullName
                Lines      = $lines
                Size       = $size
                LastWrite  = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                Status     = "OK"
            }

        } catch {
            $results += [PSCustomObject]@{
                Name       = $file.Name
                Path       = $file.FullName
                Lines      = 0
                Size       = "0 KB"
                LastWrite  = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                Status     = "ERROR: $($_.Exception.Message)"
            }
        }
    }

    # âœ… Sauvegarde du fichier JSON lisible par GPT
    $results | ConvertTo-Json -Depth 5 | Set-Content -Path $scanFile -Encoding UTF8

    # âœ‰ï¸ Log de l'opÃ©ration
    "$timestamp [GPTScanner] Analyse de $($results.Count) fichiers terminÃ©e." |
        Out-File -FilePath $logFile -Append -Encoding utf8

    foreach ($entry in $results) {
        " - $($entry.Name): $($entry.Status) ($($entry.Lines) lignes, $($entry.Size))" |
            Out-File -FilePath $logFile -Append -Encoding utf8
    }

    return $results
}

Export-ModuleMember -Function Invoke-GPTModuleScan


