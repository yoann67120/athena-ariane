# ====================================================================
# ðŸ‘ï¸ Athena.ConsoleListener.psm1 â€“ Observation Console & Apprentissage
# Version : v1.8-ExtendedSafe
# Auteur  : Athena Core Engine / Ariane V4
# Objectif :
#   - Surveiller les commandes tapÃ©es dans PowerShell
#   - Enregistrer les rÃ©sultats, erreurs et contexte
#   - Alimenter Athena.AutoLearning pour apprentissage adaptatif
#   - (Optionnel) Surveiller les changements dans /Modules et /Scripts
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleDir
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$ConsoleDir = Join-Path $MemoryDir "ConsoleLogs"
$ConsoleLog = Join-Path $ConsoleDir "ConsoleLearning.json"
$ConsoleTxt = Join-Path $LogsDir "ConsoleActivity.log"

foreach ($d in @($MemoryDir, $LogsDir, $ConsoleDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ====================================================================
# ðŸ§¾ Utilitaires
# ====================================================================
function Write-ConsoleLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $ConsoleTxt -Value "[$ts][$Level] $Message"
}

function Save-ConsoleAction {
    param(
        [string]$Command,
        [string]$Result,
        [string]$Error = "",
        [string]$Category = "general"
    )

    $entry = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        User      = $env:USERNAME
        Command   = $Command
        Result    = $Result.Trim()
        Error     = $Error.Trim()
        Category  = $Category
    }

    $log = @()
    if (Test-Path $ConsoleLog) {
        try { $log = Get-Content $ConsoleLog -Raw | ConvertFrom-Json } catch {}
    }

    $log += $entry
    $log | ConvertTo-Json -Depth 4 | Out-File $ConsoleLog -Encoding UTF8
    Write-ConsoleLog "Commande observÃ©e : $Command"
}

# ====================================================================
# ðŸ§  Analyse simple du contexte dâ€™action
# ====================================================================
function Analyze-ConsoleContext {
    param([string]$Command)
    if ($Command -match "Import-Module|Reload|Invoke|Start-Athena") { return "maintenance" }
    if ($Command -match "Remove-|Delete|Clear") { return "danger" }
    if ($Command -match "Test-|Check|Verify") { return "diagnostic" }
    if ($Command -match "Get-|Show-|List") { return "observation" }
    return "general"
}

# ====================================================================
# ðŸ§© DÃ©clenchement apprentissage (si dispo)
# ====================================================================
function Trigger-LearningCycle {
    if (Get-Command Invoke-AthenaAutoLearning -ErrorAction SilentlyContinue) {
        try {
            Start-Job { Invoke-AthenaAutoLearning -Prompt "Mets Ã  jour ta mÃ©moire console." } | Out-Null
            Write-ConsoleLog "Cycle dâ€™apprentissage dÃ©clenchÃ© suite Ã  action console."
        } catch {
            Write-ConsoleLog "Erreur dÃ©clenchement AutoLearning : $_" "ERROR"
        }
    }
}

# ====================================================================
# ðŸ” Surveillance en temps rÃ©el (modules/scripts)
# ====================================================================
function Watch-FileChanges {
    param([switch]$Start)
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $RootDir
    $watcher.IncludeSubdirectories = $true
    $watcher.Filter = "*.ps1"
    $watcher.EnableRaisingEvents = $true

    Register-ObjectEvent $watcher Changed -SourceIdentifier "AthenaFileChange" -Action {
        param($sender, $e)
        $msg = "Fichier modifiÃ© : $($e.FullPath)"
        Write-ConsoleLog $msg
        Save-ConsoleAction -Command "FILE_CHANGE" -Result $e.FullPath -Category "filewatch"
    }
    Write-ConsoleLog "Surveillance des fichiers active."
}

# ====================================================================
# ðŸ” Hook Console principal
# ====================================================================
function Register-ConsoleObserver {
    Write-Host "ðŸ‘ï¸ Athena ConsoleListener activÃ© â€“ surveillance des commandes PowerShell." -ForegroundColor Cyan

    # Hook principal du prompt PowerShell
    Register-EngineEvent PowerShell.OnCommandAdded -Action {
        param($sender, $args)
        $cmd = $args.Command
        $context = Analyze-ConsoleContext -Command $cmd
        try {
            $output = (Invoke-Expression $cmd | Out-String)
            Save-ConsoleAction -Command $cmd -Result $output -Category $context
        } catch {
            Save-ConsoleAction -Command $cmd -Result "" -Error $_ -Category "error"
        }
        if ($context -eq "maintenance" -or $context -eq "danger") {
            Trigger-LearningCycle
        }
    } | Out-Null
}

# ====================================================================
# âš™ï¸ Initialisation automatique (optionnelle)
# ====================================================================
if ($env:ATHENA_CONSOLE_OBSERVER -eq "ON") {
    Register-ConsoleObserver
}

Export-ModuleMember -Function Register-ConsoleObserver, Save-ConsoleAction, Analyze-ConsoleContext, Trigger-LearningCycle, Watch-FileChanges
Write-Host "ðŸ‘ï¸ Module Athena.ConsoleListener.psm1 chargÃ© (v1.8-ExtendedSafe)." -ForegroundColor Cyan



