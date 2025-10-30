# ====================================================================
# â™»ï¸ Athena.AutoEvolution.psm1 â€“ v2.6 Self-Healing + MemorySync Engine
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ModuleRoot
$LogsDir     = Join-Path $ProjectRoot "Logs"
$MemoryDir   = Join-Path $ProjectRoot "Memory"
$BackupsDir  = Join-Path $ProjectRoot "Backups"

foreach ($d in @($LogsDir,$MemoryDir,$BackupsDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$EvolutionLog   = Join-Path $LogsDir "AthenaEvolution.log"
$LearningMemory = Join-Path $MemoryDir "LearningSummary.json"
$ReportFile     = Join-Path $MemoryDir "AutoEvolutionReport.json"

function Write-EvoLog {
    param([string]$Msg,[string]$Level="INFO")
    $ts=(Get-Date).ToString('u')
    Add-Content -Path $EvolutionLog -Value "[$ts][$Level] $Msg"
}

function Update-LearningMemory {
    param([string]$Module,[string]$Function,[string]$Action,[string]$Code)
    $entry = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString('u')
        Module    = $Module
        Function  = $Function
        Action    = $Action
        Code      = $Code.Substring(0,[math]::Min($Code.Length,250))
    }
    $history = @()
    if (Test-Path $LearningMemory) {
        try { $history = Get-Content $LearningMemory -Raw | ConvertFrom-Json } catch {}
    }
    $history += $entry
    $history | ConvertTo-Json -Depth 4 | Out-File $LearningMemory -Encoding UTF8
    Write-EvoLog "LearningMemory mis Ã  jour pour $Function ($Action)"
}

# --------------------------------------------------------------------
# ðŸ§© CrÃ©ation de module
# --------------------------------------------------------------------
function New-AthenaModule {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Body = "function Invoke-$($Name -replace '\.','') { Write-Host 'ðŸ§© $Name opÃ©rationnel.' }"
    )
    $path = Join-Path $ModuleRoot "$Name.psm1"
    if (!(Test-Path $path)) {
        $header = @(
            "# ====================================================================",
            "# $Name â€“ Auto-generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
            "# ====================================================================",
            "Set-StrictMode -Version Latest",
            "\$ErrorActionPreference = 'SilentlyContinue'",
            $Body,
            "Export-ModuleMember -Function Invoke-$($Name -replace '\.','')"
        ) -join "`n"
        $header | Set-Content -Path $path -Encoding UTF8
        Write-EvoLog "Module crÃ©Ã© : $path"
        Update-LearningMemory $Name "Invoke-$($Name -replace '\.','')" "CrÃ©ation" $Body
        Write-Host "ðŸ§© Nouveau module crÃ©Ã© : $Name" -ForegroundColor Cyan
    }
}

# --------------------------------------------------------------------
# ðŸ§  Ajout & rechargement automatique
# --------------------------------------------------------------------
function Add-AthenaFunction {
    param([string]$TargetModule,[string]$FunctionCode)

    $root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
    $path = Get-ChildItem -Path $root -Recurse -Filter "$TargetModule.psm1" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $path) {
        Write-Warning "Module $TargetModule introuvable."
        return
    }

    $bak = "$($path.FullName).bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
    Copy-Item $path.FullName $bak -Force

    Add-Content -Path $path.FullName -Value "`n$FunctionCode"
    Write-Host "âš™ï¸ Fonction ajoutÃ©e Ã  $($path.Name)" -ForegroundColor Cyan
    Update-LearningMemory $TargetModule ($FunctionCode -split '\s+')[1] "Ajout" $FunctionCode

    Import-Module $path.FullName -Force -Global
    Write-Host "âœ… Module $TargetModule rechargÃ©." -ForegroundColor Green
}

# --------------------------------------------------------------------
# ðŸ”¹ Fonction principale
# --------------------------------------------------------------------
function Invoke-AthenaAutoEvolution {
    [CmdletBinding()] param([string]$Prompt = "Aucune instruction reÃ§ue.")
    Write-Host "`nâ™»ï¸ DÃ©marrage du cycle Auto-Evolution..." -ForegroundColor Yellow
    Write-EvoLog "Cycle dÃ©marrÃ© : $Prompt"

    if ($Prompt -match 'Auto-Backup' -or $Prompt -match 'SelfVerification') {
        Write-Host "ðŸ§  Phase 17 â€“ Auto-Consolidation & Backup" -ForegroundColor Cyan
        New-AthenaModule -Name "Athena.AutoBackup"
        New-AthenaModule -Name "Athena.SelfVerification"
        Write-Host "âœ… Phase 17 gÃ©nÃ©rÃ©e avec succÃ¨s." -ForegroundColor Green
    }
    elseif ($Prompt -match 'Add-AthenaFunction' -or
            $Prompt -match 'Auto-Rewrite' -or
            $Prompt -match 'rÃ©Ã©cris' -or
            $Prompt -match 'rÃ©Ã©criture' -or
            $Prompt -match 'ajoute une fonction' -or
            $Prompt -match 'modifie ton code') {

        Write-Host "ðŸ§  Phase 18 â€“ Auto-RÃ©Ã©criture" -ForegroundColor Cyan
        $target = "Athena.AutoEvolution"
        $code = @'
function Invoke-AthenaHelloAutoWrite {
    Write-Host "ðŸš€ Fonction gÃ©nÃ©rÃ©e automatiquement par Auto-RÃ©Ã©criture." -ForegroundColor Yellow
}
'@
        Add-AthenaFunction -TargetModule $target -FunctionCode $code
        Write-Host "âœ… Phase 18 : fonction ajoutÃ©e et module rechargÃ©." -ForegroundColor Green
    }
    else {
        Write-Host "ðŸ’« Aucune crÃ©ation spÃ©cifique demandÃ©e, Ã©volution classique." -ForegroundColor Gray
    }

    Invoke-AthenaAutoExport
    Invoke-AthenaAutoTest
    Write-Host "âœ… Cycle Auto-Evolution terminÃ©.`n" -ForegroundColor Green
}

# --------------------------------------------------------------------
# ðŸ”§ Auto-Export
# --------------------------------------------------------------------
function Invoke-AthenaAutoExport {
    $modulePath = $MyInvocation.MyCommand.Path
    $functions  = (Select-String -Path $modulePath -Pattern 'function\s+([A-Za-z0-9\-_]+)' |
                   ForEach-Object { $_.Matches.Groups[1].Value }) |
                   Where-Object { $_ -like 'Invoke-Athena*' -or $_ -like 'Add-Athena*' }

    if ($functions) {
        $exportLine = "Export-ModuleMember -Function $($functions -join ',')"
        $content = Get-Content $modulePath -Raw
        if ($content -match 'Export-ModuleMember') {
            $content = $content -replace 'Export-ModuleMember[^\r\n]*', $exportLine
        } else {
            $content += "`n$exportLine"
        }
        $content | Set-Content -Path $modulePath -Encoding UTF8
        Import-Module $modulePath -Force -Global
        Write-Host "ðŸ”„ Export mis Ã  jour et module rechargÃ©." -ForegroundColor Yellow
    }
}

# --------------------------------------------------------------------
# ðŸ§ª Auto-Test & Rollback
# --------------------------------------------------------------------
function Invoke-AthenaAutoTest {
    $logFile = Join-Path $LogsDir "AthenaAutoTest.log"
    $report  = [ordered]@{ Date=(Get-Date).ToString('u'); Functions=@(); Errors=@() }

    Write-Host "`nðŸ§ª VÃ©rification automatique des fonctions exportÃ©es..." -ForegroundColor Cyan
    Add-Content -Path $logFile -Value "=== Test du $(Get-Date -Format 'u') ==="

    try {
        $exports = (Get-Module Athena.AutoEvolution).ExportedCommands.Keys
        foreach ($func in $exports) {
            try {
                $null = Get-Command $func -ErrorAction Stop
                Add-Content -Path $logFile -Value "âœ… $func dÃ©tectÃ©e."
                $report.Functions += $func
            } catch {
                Add-Content -Path $logFile -Value "âŒ $func manquante."
                $report.Errors += $func
            }
        }

        if ($report.Errors.Count -gt 0) {
            Write-Warning "âš ï¸ Fonctions manquantes, tentative de rollback..."
            $bak = Get-ChildItem "$ModuleRoot\Athena.AutoEvolution.psm1.bak_*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($bak) {
                Copy-Item $bak.FullName "$ModuleRoot\Athena.AutoEvolution.psm1" -Force
                Import-Module "$ModuleRoot\Athena.AutoEvolution.psm1" -Force -Global
                Add-Content -Path $logFile -Value "ðŸ” Rollback appliquÃ© depuis $($bak.Name)"
                $report.Rollback = $bak.Name
            }
        } else {
            Write-Host "âœ… Toutes les fonctions exportÃ©es sont accessibles." -ForegroundColor Green
        }
    } catch {
        Add-Content -Path $logFile -Value "âŒ Erreur durant test : $_"
    }

    $report | ConvertTo-Json -Depth 4 | Out-File $ReportFile -Encoding UTF8
    Add-Content -Path $logFile -Value "`n"
}

Invoke-AthenaAutoExport
Invoke-AthenaAutoTest
Write-Host "âœ… Module Athena.AutoEvolution chargÃ© (v2.6 â€“ Self-Healing + AutoTest + Rollback)."



