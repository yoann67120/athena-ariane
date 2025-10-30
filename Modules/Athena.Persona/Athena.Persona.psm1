# ====================================================================
# ðŸ’¬ Athena.Persona.psm1 â€“ Adaptation linguistique & Ã©motionnelle
# Version : v1.2-Stable-Robust (auto-rÃ©paration + ton adaptatif sÃ©curisÃ©)
# Description : Ajuste le ton et le style de la rÃ©ponse selon le profil linguistique de lâ€™utilisateur.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$ModuleDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir     = Split-Path -Parent $ModuleDir
$MemoryDir   = Join-Path $RootDir "Memory"
$ProfileFile = Join-Path $MemoryDir "Profile.Linguistic.json"

# ====================================================================
# ðŸ“ Initialisation du profil linguistique (auto-rÃ©paration)
# ====================================================================
function Initialize-AthenaLinguisticProfile {
    if (!(Test-Path $ProfileFile)) {
        $DefaultProfile = @{
            AverageLength = 40
            Emotion       = 0.3
            DominantType  = "neutre"
            PreferredTone = "calme"
        }
        $DefaultProfile | ConvertTo-Json -Depth 3 | Set-Content -Path $ProfileFile -Encoding UTF8
        Write-Host "ðŸ©¹ Profil linguistique par dÃ©faut crÃ©Ã©." -ForegroundColor DarkCyan
    }
}

Initialize-AthenaLinguisticProfile

# ====================================================================
# ðŸ“– Lecture du profil linguistique
# ====================================================================
function Get-AthenaLinguisticProfile {
    try {
        $json = Get-Content $ProfileFile -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($json)) { throw "Fichier vide." }
        return ($json | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        $errMsg = if ($_.Exception) { $_.Exception.Message } else { "Erreur inconnue durant la lecture du profil linguistique." }
        Write-Warning "âš ï¸ Erreur lecture profil linguistique : $errMsg"
        # Auto-rÃ©paration du profil
        Remove-Item $ProfileFile -ErrorAction SilentlyContinue
        Initialize-AthenaLinguisticProfile
        return (Get-Content $ProfileFile -Raw | ConvertFrom-Json)
    }
}

# ====================================================================
# ðŸ’¡ Fonction principale â€“ Adaptation du ton
# ====================================================================
function Invoke-AthenaPersona {
    param([string]$Prompt)

    $Profile = Get-AthenaLinguisticProfile
    if (-not $Profile) {
        Write-Warning "âš ï¸ Profil linguistique non chargÃ©, utilisation du ton neutre."
        $Profile = @{ PreferredTone = "neutre" }
    }

    switch ($Profile.PreferredTone) {
        "calme" {
            $prefix = "RÃ©ponds avec douceur, empathie et clartÃ©. "
        }
        "directif" {
            $prefix = "RÃ©ponds de maniÃ¨re concise, efficace et orientÃ©e action. "
        }
        "curieux" {
            $prefix = "RÃ©ponds avec curiositÃ©, pÃ©dagogie et clartÃ© dâ€™explication. "
        }
        "Ã©motionnel" {
            $prefix = "RÃ©ponds avec chaleur, Ã©motion et bienveillance. "
        }
        "analytique" {
            $prefix = "RÃ©ponds de faÃ§on structurÃ©e et logique, en expliquant le raisonnement. "
        }
        default {
            $prefix = "RÃ©ponds de faÃ§on naturelle et claire. "
        }
    }

    $PromptAdapted = "$prefix Voici la requÃªte : $Prompt"
    Write-Host "ðŸ’¬ [Persona] Ton appliquÃ© : $($Profile.PreferredTone)" -ForegroundColor Green
    return $PromptAdapted
}

# ====================================================================
# ðŸ“¤ Export des fonctions
# ====================================================================
Export-ModuleMember -Function Invoke-AthenaPersona, Get-AthenaLinguisticProfile
Write-Host "âœ… Athena.Persona.psm1 chargÃ© (v1.2-Stable-Robust â€“ Adaptation linguistique opÃ©rationnelle)." -ForegroundColor Cyan























































