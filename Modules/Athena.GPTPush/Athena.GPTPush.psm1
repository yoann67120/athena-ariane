# ====================================================================
# ðŸ“¡ Athena.GPTPush.psm1
# Version : v1.0 - Transmetteur automatique vers GPT (via HTTP)
# Auteur  : Yoann Rousselle / Athena Core
# RÃ´le   : Envoie Ã  GPT (ou n8n/Gateway) le contenu de fichiers-clÃ©s dâ€™Athena
# ====================================================================

function Send-GPTFile {
    param (
        [string]$FilePath,
        [string]$TargetUrl = "http://localhost:9191/gpt/ingest"
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "âŒ Fichier introuvable : $FilePath"
        return
    }

    $filename = Split-Path $FilePath -Leaf
    $json = Get-Content $FilePath -Raw -Encoding UTF8

    $payload = @{
        filename = $filename
        content = $json
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-WebRequest -Uri $TargetUrl -Method POST -Body $payload -ContentType "application/json" -UseBasicParsing
        Write-Host "âœ… Transmis : $filename â†’ $TargetUrl ($($response.StatusCode))"
    }
    catch {
        Write-Host "âŒ Erreur dâ€™envoi : $_"
    }
}

function Send-AllGPTFiles {
    $base = (Get-Location).Path
    $memory = Join-Path $base "Memory"
    $filesToSend = @( "GPT_Scan.json", "action_gpt.json", "EmotionState.json", "Status.json" )

    foreach ($f in $filesToSend) {
        $path = Join-Path $memory $f
        Send-GPTFile -FilePath $path
    }
}

Export-ModuleMember -Function Send-GPTFile, Send-AllGPTFiles


