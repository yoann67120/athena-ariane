# ====================================================================
# ðŸŽ›ï¸ Cockpit.Actions.psm1 â€“ v1.3-FullInteractive
# Objectif : Relier les boutons du Cockpit Ã  leurs modules Athena
# Auteur : Ariane V4 / Athena Core
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === RÃ©pertoires de base ===
$RootDir   = "$env:ARIANE_ROOT"
$Modules   = Join-Path $RootDir "Modules"
$LogsDir   = Join-Path $RootDir "Logs"
$ActionsLog = Join-Path $LogsDir "CockpitActions.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-ActionLog {
    param([string]$Message,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $ActionsLog -Value "[$t][$Level] $Message"
    Write-Host $Message -ForegroundColor DarkGray
}

# ====================================================================
# ðŸ”§ FONCTION PRINCIPALE
# ====================================================================
function Invoke-CockpitAction {
    param([string]$Name)

    $StartTime = Get-Date
    Write-ActionLog "âž¡ï¸ Action reÃ§ue : $Name"

    try {
        switch ($Name.ToLower()) {

            # ðŸ§  Liste des actions
            "command" {
                $msg = "Ouverture de la boÃ®te Ã  actions globale."
            }

            "maintenance" {
                Import-Module "$Modules\Athena.JSONCleaner.psm1" -Force -Global | Out-Null
                Import-Module "$Modules\Athena.SelfRepair.psm1" -Force -Global | Out-Null
                Invoke-AthenaJSONCleaner | Out-Null
                Invoke-AthenaSelfRepair | Out-Null
                $msg = "Maintenance et nettoyage terminÃ©s avec succÃ¨s."
            }

            "sync" {
                Import-Module "$Modules\Athena.SelfCoordinator.psm1" -Force -Global | Out-Null
                Invoke-AthenaCoordinationCycle | Out-Null
                $msg = "Cycle de coordination exÃ©cutÃ©."
            }

            "projects" {
                Import-Module "$Modules\Athena.ProjectFactory.psm1" -Force -Global | Out-Null
                Invoke-AthenaProjectFactory | Out-Null
                $msg = "Usine Ã  projets initialisÃ©e."
            }

            "voice" {
                Import-Module "$Modules\Athena.Voice.psm1" -Force -Global | Out-Null
                if (Get-Command Set-AthenaVoice -ErrorAction SilentlyContinue) {
                    Set-AthenaVoice -Enable
                    $msg = "Voix Athena activÃ©e."
                } else {
                    $msg = "Voix Athena non disponible."
                }
            }

            "learning" {
                Import-Module "$Modules\Athena.Learning.psm1" -Force -Global | Out-Null
                Invoke-AthenaLearning | Out-Null
                $msg = "Cycle dâ€™apprentissage complÃ©tÃ©."
            }

            "web" {
                Import-Module "$Modules\Athena.WebSearch.psm1" -Force -Global | Out-Null
                if (Get-Command Invoke-AthenaWebSearch -ErrorAction SilentlyContinue) {
                    Invoke-AthenaWebSearch
                    $msg = "Moteur de recherche Athena lancÃ©."
                } else {
                    $msg = "Module de recherche web non installÃ©."
                }
            }

            "security" {
                Import-Module "$Modules\Athena.GuardianCheck.psm1" -Force -Global | Out-Null
                if (Get-Command Invoke-AthenaGuardianCheck -ErrorAction SilentlyContinue) {
                    Invoke-AthenaGuardianCheck
                    $msg = "VÃ©rification Guardian exÃ©cutÃ©e."
                } else {
                    $msg = "Module Guardian non disponible."
                }
            }

            default {
                $msg = "Action inconnue : $Name"
                Write-ActionLog $msg "WARN"
            }
        }

        # Convertir en texte pur pour Ã©viter op_Addition
        $msg = [string]$msg
        Write-ActionLog "[SUCCESS] $msg"
        return $msg

    } catch {
        $err = "Erreur durant lâ€™action $Name : $($_.Exception.Message)"
        Write-ActionLog "[ERROR] $err"
        return [string]$err
    } finally {
        $dur = (Get-Date) - $StartTime
        Write-ActionLog "$Name DurÃ©e : $($dur.TotalSeconds) s"
    }
}

Export-ModuleMember -Function Invoke-CockpitAction
Write-Host "âœ… Module Cockpit.Actions.psm1 chargÃ© (v1.3-FullInteractive)" -ForegroundColor Green


