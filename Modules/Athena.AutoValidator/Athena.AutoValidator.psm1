# ====================================================================
# Athena.AutoValidator.psm1
# Validation, test et correction automatique des modules d'Athena
# Version : v2.0-SafeCore
# Auteur  : Yoann Rousselle / Athena Core
# ====================================================================

$ErrorActionPreference = 'SilentlyContinue'

function Write-ValidatorLog {
    param([string]$msg)
    $logFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\Logs\AutoValidator.log'
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    "$timestamp [AutoValidator] $msg" | Out-File -Append -FilePath $logFile -Encoding UTF8
}

# Vérifie la syntaxe PowerShell d’un bloc de code
function Test-PwshSyntax {
    param([string]$Code)
    try { [scriptblock]::Create($Code) | Out-Null; return $true }
    catch { Write-ValidatorLog ("SyntaxError: " + $_.Exception.Message); return $false }
}

# Teste l'import d'un module temporaire
function Test-ImportModule {
    param([string]$Path)
    try {
        $m = Import-Module -Name $Path -Force -PassThru -ErrorAction Stop -Scope Local
        if ($m) { Remove-Module -ModuleInfo $m -Force -ErrorAction SilentlyContinue }
        return $true
    }
    catch { Write-ValidatorLog ("ImportError: " + $_.Exception.Message); return $false }
}

# Lance un test complet de validation
function Invoke-AthenaValidation {
    param(
        [string]$Name,
        [string]$Content,
        [string]$SandboxPath,
        [string]$FinalPath
    )

    Write-ValidatorLog "Validation Start for $Name"

    try { Set-Content -Path $SandboxPath -Value $Content -Encoding UTF8 }
    catch {
        return @{ Status = 'error'; Message = 'Sandbox write failed' }
    }

    if (-not (Test-PwshSyntax $Content)) {
        return @{ Status = 'error'; Message = 'PowerShell syntax error' }
    }

    if (-not (Test-ImportModule $SandboxPath)) {
        return @{ Status = 'error'; Message = 'Module import failed' }
    }

    try {
        if (Test-Path $FinalPath) {
            $backup = $FinalPath + ('.bak_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
            Copy-Item $FinalPath $backup -Force
            Write-ValidatorLog "Backup created: $backup"
        }

        Move-Item $SandboxPath $FinalPath -Force
        Write-ValidatorLog "Module $Name validated and installed."
        return @{ Status = 'ok'; Message = 'OK' }
    }
    catch {
        Write-ValidatorLog ("FinalCopyError: " + $_.Exception.Message)
        return @{ Status = 'error'; Message = 'Final copy failed' }
    }
}

Export-ModuleMember -Function Invoke-AthenaValidation


