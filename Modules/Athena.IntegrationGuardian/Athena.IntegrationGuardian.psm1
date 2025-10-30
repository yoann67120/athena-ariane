# ====================================================================
# ðŸ§  Athena.IntegrationGuardian.psm1 â€“ v1.0-Stable-FIGÃ‰
# --------------------------------------------------------------------
# Objectif :
#   Surveille et vÃ©rifie automatiquement les intÃ©grations externes dâ€™Athena.
#   Si un service (n8n, NodeRED, Ollama, LMStudio, Supabase, etc.)
#   nâ€™est pas Ã  jour ou prÃ©sente une anomalie, le module relance un test
#   dâ€™intÃ©gration complet et met Ã  jour IntegrationContexts.json.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === ðŸ“ RÃ©pertoires et fichiers ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$MemoryDir  = Join-Path $RootDir "Memory"
$LogsDir    = Join-Path $RootDir "Logs"
$ContextsFile = Join-Path $MemoryDir "IntegrationContexts.json"
$LogFile      = Join-Path $LogsDir "IntegrationGuardian.log"

# === ðŸ§© Fonction principale : Invoke-IntegrationGuardian ===
function Invoke-IntegrationGuardian {
    Write-Host "`nðŸ§  Lancement du cycle de vÃ©rification hebdomadaire des intÃ©grations..." -ForegroundColor Cyan
    "[$(Get-Date)] DÃ©marrage du cycle IntegrationGuardian" | Out-File $LogFile -Encoding UTF8

    if (-not (Test-Path $ContextsFile)) {
        "âš ï¸ Aucun fichier IntegrationContexts.json trouvÃ© â€“ crÃ©ation automatique." | Tee-Object -FilePath $LogFile -Append
@'
{
  "n8n": { "status": "unknown", "lastCheck": "" },
  "NodeRED": { "status": "unknown", "lastCheck": "" },
  "Ollama": { "status": "unknown", "lastCheck": "" },
  "LMStudio": { "status": "unknown", "lastCheck": "" },
  "Supabase": { "status": "unknown", "lastCheck": "" },
  "AutoGPT": { "status": "unknown", "lastCheck": "" },
  "LangChain": { "status": "unknown", "lastCheck": "" }
}
'@ | Out-File $ContextsFile -Encoding UTF8
    }

    try {
        $data = Get-Content $ContextsFile -Raw | ConvertFrom-Json
        $changed = $false

        foreach ($ctx in $data.PSObject.Properties.Name) {
            $status = $data.$ctx.status
            $lastCheck = $data.$ctx.lastCheck

            if (-not $lastCheck -or $status -ne "OK" -or
                ((Get-Date) - [datetime]$lastCheck).Days -ge 7) {
                "ðŸ”„ Revalidation du service : $ctx" | Tee-Object -FilePath $LogFile -Append
                try {
                    Import-Module (Join-Path $RootDir "Modules\Athena.IntegrationAdvisor.psm1") -Force -Global
                    if (Get-Command Invoke-IntegrationCheck -ErrorAction SilentlyContinue) {
                        Invoke-IntegrationCheck -Silent
                    }
                    $data.$ctx.status = "OK"
                    $data.$ctx.lastCheck = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                    $changed = $true
                    "âœ… $ctx : Statut actualisÃ©" | Tee-Object -FilePath $LogFile -Append
                } catch {
                    "âŒ Erreur lors de la vÃ©rification de $ctx : $_" | Tee-Object -FilePath $LogFile -Append
                }
            } else {
                "ðŸŸ¢ $ctx : DÃ©jÃ  validÃ© rÃ©cemment" | Tee-Object -FilePath $LogFile -Append
            }
        }

        if ($changed) {
            $data | ConvertTo-Json -Depth 5 | Out-File $ContextsFile -Encoding UTF8
            "ðŸ’¾ Fichier IntegrationContexts.json mis Ã  jour." | Tee-Object -FilePath $LogFile -Append
        }

        "ðŸª¶ Cycle IntegrationGuardian terminÃ© avec succÃ¨s." | Tee-Object -FilePath $LogFile -Append
        Write-Host "âœ… Cycle IntegrationGuardian terminÃ©. Consulte le log pour les dÃ©tails." -ForegroundColor Green
    }
    catch {
        Write-Host "âŒ Erreur lors de la lecture ou mise Ã  jour du fichier : $_" -ForegroundColor Red
        Add-Content $LogFile "âŒ Erreur : $_"
    }
}

Export-ModuleMember -Function Invoke-IntegrationGuardian

Write-Host "ðŸ§  Module Athena.IntegrationGuardian.psm1 chargÃ© (v1.0-Stable-FIGÃ‰)." -ForegroundColor Cyan



