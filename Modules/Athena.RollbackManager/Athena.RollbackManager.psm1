# ====================================================================
# Athena.RollbackManager.psm1
# Restauration automatique des versions sécurisées d'Athena
# Version : v1.0-Stable
# Auteur  : Yoann Rousselle / Athena Core
# ====================================================================

$ErrorActionPreference = 'SilentlyContinue'

function Write-RollbackLog {
    param([string]$msg)
    $logFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\Logs\AutoRepair.log'
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    "$timestamp [RollbackManager] $msg" | Out-File -Append -FilePath $logFile -Encoding UTF8
}

# Restaure le dernier fichier .bak disponible
function Invoke-AthenaRollback {
    param([string]$TargetFile)

    $dir = Split-Path $TargetFile
    $name = Split-Path $TargetFile -Leaf
    $pattern = "$name.bak_*"
    $bakFile = Get-ChildItem -Path $dir -Filter $pattern | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($bakFile) {
        try {
            Copy-Item $bakFile.FullName $TargetFile -Force
            Write-RollbackLog "Rollback done from $($bakFile.Name)"
            return $true
        } catch {
            Write-RollbackLog "Rollback failed: $($_.Exception.Message)"
            return $false
        }
    } else {
        Write-RollbackLog "No backup found for $TargetFile"
        return $false
    }
}

Export-ModuleMember -Function Invoke-AthenaRollback



