# ====================================================================
# Athena.AutoValidator.psm1
# Moteur de test, correction et validation automatique des modules GPT
# ====================================================================

$ErrorActionPreference = 'SilentlyContinue'

function Write-LogLocal {
    param($msg)
    $logFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\Logs\AutoRepair.log'
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    "$timestamp [AutoValidator] $msg" | Out-File -Append -FilePath $logFile -Encoding UTF8
}

function Test-PwshSyntax {
    param([string]$Code)
    try { $null = [scriptblock]::Create($Code); return $true }
    catch { Write-LogLocal "SyntaxError: $($_.Exception.Message)"; return $false }
}

function Test-ImportModule {
    param([string]$Path)
    try { Import-Module $Path -Force -PassThru | Out-Null; Remove-Module (Split-Path $Path -LeafBase) -Force; return $true }
    catch { Write-LogLocal "ImportError: $($_.Exception.Message)"; return $false }
}

function Invoke-AthenaValidation {
    param(
        [string]$Name,
        [string]$Content,
        [string]$SandboxPath,
        [string]$FinalPath
    )
    Write-LogLocal "Début validation pour $Name"

    try {
        Set-Content -Path $SandboxPath -Value $Content -Encoding UTF8
    } catch {
        return @{ Status = 'error'; Message = 'Échec écriture sandbox' }
    }

    if (-not (Test-PwshSyntax $Content)) {
        return @{ Status = 'error'; Message = 'Erreur syntaxique PowerShell' }
    }

    if (-not (Test-ImportModule $SandboxPath)) {
        return @{ Status = 'error'; Message = 'Échec import module test' }
    }

    try {
        if (Test-Path $FinalPath) {
            $backup = $FinalPath + ('.bak_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
            Copy-Item -Path $FinalPath -Destination $backup -Force
            Write-LogLocal "Backup créé : $backup"
        }
        Move-Item -Path $SandboxPath -Destination $FinalPath -Force
        Write-LogLocal "Module $Name validé et installé."
        return @{ Status = 'ok'; Message = 'OK' }
    } catch {
        Write-LogLocal "Erreur copie finale : $($_.Exception.Message)"
        return @{ Status = 'error'; Message = 'Erreur copie finale' }
    }
}

function Invoke-AthenaAutoCorrection {
    param([string]$Name, [string]$ErrorMsg, [string]$OriginalContent)
    Write-LogLocal "Tentative d’auto-correction pour $Name"
    # Simulation : GPT proposera une correction (à implémenter via WebSocket)
    # Ici on retourne $null pour attendre la correction réelle par GPT
    return $null
}

Export-ModuleMember -Function Invoke-AthenaValidation, Invoke-AthenaAutoCorrection



