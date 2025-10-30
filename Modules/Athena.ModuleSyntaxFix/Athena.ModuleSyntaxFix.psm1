# ====================================================================
# Athena.ModuleSyntaxFix.psm1 â€“ Correcteur syntaxique global des modules
# Version : v1.0-SyntaxCleaner (2025-10-17)
# Objectif : Corriger automatiquement les modules mal gÃ©nÃ©rÃ©s.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$Modules   = Join-Path $RootDir "Modules"
$LogFile   = Join-Path $RootDir "Logs\ModuleSyntaxFix.log"

function Write-FixLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

function Repair-AthenaModule {
    param([string]$File)

    $content = Get-Content $File -Raw -ErrorAction SilentlyContinue

    # === 1ï¸âƒ£ Corriger la variable d'erreur ===
    if ($content -notmatch '\$ErrorActionPreference') {
        $content = $content -replace '(?m)^\s*SilentlyContinue\s*=\s*.+$', '$ErrorActionPreference = ''SilentlyContinue'''
    }

    # === 2ï¸âƒ£ Corriger le nom de fonction ===
    $content = $content -replace 'function\s+Invoke-Athena\.', 'function Invoke-Athena_'
    $content = $content -replace 'Export-ModuleMember\s+-Function\s+Invoke-Athena\.', 'Export-ModuleMember -Function Invoke-Athena_'

    # === 3ï¸âƒ£ VÃ©rifier que tout est bien encodÃ© ===
    if ($content -notmatch 'Export-ModuleMember') {
        $content += "`nExport-ModuleMember -Function *"
    }

    # === 4ï¸âƒ£ RÃ©Ã©crire proprement le fichier ===
    $content | Set-Content -Path $File -Encoding UTF8
    Write-FixLog "âœ… CorrigÃ© : $File"
    Write-Host "âœ… CorrigÃ© : $File" -ForegroundColor Green
}

function Invoke-AthenaModuleSyntaxFix {
    Write-Host "ðŸ§  DÃ©marrage du correcteur global des modules..." -ForegroundColor Cyan
    if (!(Test-Path $Modules)) {
        Write-Host "âŒ Dossier Modules introuvable : $Modules" -ForegroundColor Red
        return
    }

    $files = Get-ChildItem -Path $Modules -Filter "*.psm1" -File -Recurse
    if ($files.Count -eq 0) {
        Write-Host "âš ï¸ Aucun module trouvÃ© Ã  corriger." -ForegroundColor DarkYellow
        return
    }

    foreach ($f in $files) {
        Repair-AthenaModule -File $f.FullName
    }

    Write-Host "âœ… VÃ©rification terminÃ©e. Tous les modules ont Ã©tÃ© corrigÃ©s si nÃ©cessaire." -ForegroundColor Cyan
    Write-FixLog "Fin du correctif global Ã  $(Get-Date)"
}

Export-ModuleMember -Function Invoke-AthenaModuleSyntaxFix
Write-Host "Module Athena.ModuleSyntaxFix chargÃ© (v1.0-SyntaxCleaner)." -ForegroundColor Cyan



