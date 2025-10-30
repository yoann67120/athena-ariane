# ====================================================================
# ðŸ”’ Athena.Freeze.psm1 â€“ Figement du socle stable Arianeâ€“Athena v3.2
# Version : v1.0
# Objectif :
#   - Calculer le hash SHA256 de chaque module
#   - Sauvegarder les informations dans Memory\IntegrityAudit.json
#   - CrÃ©er une archive ZIP complÃ¨te du socle
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

$RootDir     = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ModulesDir  = Join-Path $RootDir "Modules"
$MemoryDir   = Join-Path $RootDir "Memory"
$ArchiveDir  = Join-Path $RootDir "Archive"
$AuditFile   = Join-Path $MemoryDir "IntegrityAudit.json"
$ZipFile     = Join-Path $ArchiveDir "Stable_3.2.zip"

if (!(Test-Path $ArchiveDir)) { New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null }

function Invoke-AthenaFreeze {
    Write-Host "`nðŸ”’ DÃ©but du figement du socle Athena v3.2..." -ForegroundColor Cyan

    $hashes = @()
    Get-ChildItem $ModulesDir -Filter *.psm1 -File | ForEach-Object {
        $sha = Get-FileHash $_.FullName -Algorithm SHA256
        $hashes += [ordered]@{
            Module = $_.Name
            Hash   = $sha.Hash
            SizeKB = [math]::Round($_.Length / 1KB, 2)
            Date   = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        }
    }

    $audit = [ordered]@{
        Date       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Version    = "v3.2"
        TotalFiles = (@($hashes).Count)
        Modules    = $hashes
    }

    $audit | ConvertTo-Json -Depth 5 | Set-Content -Path $AuditFile -Encoding UTF8
    Write-Host "âœ… Audit dâ€™intÃ©gritÃ© sauvegardÃ© : $AuditFile" -ForegroundColor Green

    try {
        Compress-Archive -Path (Join-Path $ModulesDir "*") -DestinationPath $ZipFile -Force
        Write-Host "ðŸ“¦ Archive crÃ©Ã©e : $ZipFile" -ForegroundColor Green
    } catch {
        Write-Warning "âš ï¸ Erreur lors de la crÃ©ation de lâ€™archive : $_"
    }

    Write-Host "ðŸ”’ Socle Arianeâ€“Athena figÃ© en version v3.2." -ForegroundColor Cyan
}

Export-ModuleMember -Function Invoke-AthenaFreeze
Write-Host "âœ… Module Athena.Freeze.psm1 chargÃ© (figement prÃªt)."




