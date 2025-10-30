# ====================================================================
# ðŸ’¬ Athena.Conversant.psm1 â€“ Interface conversationnelle hybride
# Version : v3.6-AutoClean-Stable
# Auteur  : Ariane V4 / Athena Core Engine
# Objectif : conversation naturelle + exÃ©cution intelligente des actions systÃ¨me
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === Importations automatiques ===
$deps = @(
    "Athena.HybridCore.psm1",
    "Athena.Voice.psm1",
    "Athena.Sound.psm1",
    "ActionEngine.psm1",
    "AutoPatch.psm1"
)
foreach ($dep in $deps) {
    $path = Join-Path $PSScriptRoot $dep
    if (Test-Path $path) {
        Import-Module $path -Force -Global
    } else {
        Write-Warning "âš ï¸ DÃ©pendance manquante : $dep"
    }
}

# === Configuration mÃ©moire ===
$Root      = Split-Path -Parent $PSScriptRoot
$MemoryDir = Join-Path $Root "Memory"
if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Path $MemoryDir | Out-Null }
$ConvLog   = Join-Path $MemoryDir "Conversations.log"

# ====================================================================
# âš¡ Analyse dâ€™intention et exÃ©cution dâ€™action
# ====================================================================
function Invoke-AthenaAction {
    param([string]$Text)

    $cmd = $Text.ToLower()
    switch -regex ($cmd) {

        # === Nouvelle intention : crÃ©ation de module ===
        "crÃ©e|creer|nouveau.?module|ajoute.?module|genere.?module" {
            Write-Host "ðŸ§© DÃ©tection dâ€™une intention de crÃ©ation de module..." -ForegroundColor Cyan
            if (Get-Command Invoke-AthenaVoice -ErrorAction SilentlyContinue) {
                try { Invoke-AthenaVoice -Text "CrÃ©ation de module en cours..." -Silent } catch {}
            }

            $prompt = "$Text. RÃ©ponds uniquement avec le code PowerShell complet du module, sans explication ni commentaire."
            try {
                $response = Invoke-AthenaHybrid -Prompt $prompt
                Write-Host "ðŸ§  RÃ©ponse GPT Architecte reÃ§ue â€“ tentative dâ€™application automatique..." -ForegroundColor Cyan

                # ðŸ§¹ Nettoyage du code PowerShell (suppression des balises Markdown)
                if ($response -match '```powershell([\s\S]*?)```') { $response = $matches[1].Trim() }
                elseif ($response -match '```([\s\S]*?)```') { $response = $matches[1].Trim() }

                Apply-GPTCode -Code $response
                if (Get-Command Invoke-AthenaVoice -ErrorAction SilentlyContinue) {
                    try { Invoke-AthenaVoice -Text "Module gÃ©nÃ©rÃ© et chargÃ© avec succÃ¨s." -Silent } catch {}
                }
                return "âœ… Module gÃ©nÃ©rÃ© automatiquement par le GPT Architecte."
            }
            catch {
                Write-Warning "âš ï¸ Erreur durant la crÃ©ation automatique de module : $_"
                if (Get-Command Invoke-AthenaVoice -ErrorAction SilentlyContinue) {
                    try { Invoke-AthenaVoice -Text 'Erreur lors de la gÃ©nÃ©ration du module.' -Silent } catch {}
                }
                return "âŒ Erreur lors de la gÃ©nÃ©ration du module."
            }
        }

        # === Intentions standards ===
        "rÃ©pare|repare|auto.?repair|patch" { return Invoke-ActionPlan -Plan "AutoRepair" }
        "synchronis(e|er)|mÃ©moire|memoire" { return Invoke-ActionPlan -Plan "MemorySync" }
        "harmoni(e|e)|Ã©quilibre|equilibre" { return Invoke-ActionPlan -Plan "AutoHarmony" }
        "apprends|apprentissage|learning"  { return Invoke-ActionPlan -Plan "AutoLearning" }
        "rapport"                         { return Invoke-ActionPlan -Plan "AutoReport" }
        "Ã©volution|evolution"             { return Invoke-ActionPlan -Plan "AutoEvolution" }
        default                           { return $null }
    }
}

# ====================================================================
# ðŸ§  Moteur de conversation principale
# ====================================================================
function Invoke-AthenaConversant {
    Write-Host "`nðŸ’¬ Mode conversation directe activÃ©." -ForegroundColor Cyan
    Write-Host "Tape 'exit' pour quitter.`n" -ForegroundColor DarkGray

    while ($true) {
        $input = Read-Host "ðŸ—£ï¸ Toi"
        if ($input -eq "exit") {
            Write-Host "`nðŸ‘‹ Fin de la session.`n" -ForegroundColor Yellow
            break
        }

        Add-Content -Path $ConvLog -Value ("[Toi] " + $input)

        try {
            # ðŸ§  Reformulation automatique pour GPT Architecte
            if ($input -match "crÃ©e|creer|corrige|corriger|module|psm1|script|patch|code") {
                $input = "$input. RÃ©ponds uniquement avec le code PowerShell complet du module, sans explication ni commentaire."
                Write-Host "ðŸ§© Reformulation automatique pour GPT Architecte..." -ForegroundColor Cyan
            }

            $actionResult = Invoke-AthenaAction -Text $input
            if ($actionResult) { $response = $actionResult }
            else { $response = Invoke-AthenaHybrid -Prompt $input }
        }
        catch {
            $response = "âš ï¸ Erreur interne pendant la rÃ©ponse."
        }

        if ([string]::IsNullOrWhiteSpace($response)) { $response = "(aucune rÃ©ponse)" }
        Add-Content -Path $ConvLog -Value ("[Athena] " + $response)
        Write-Host "ðŸ¤– Athena : $response" -ForegroundColor Green

        if (Get-Command Invoke-AthenaVoice -ErrorAction SilentlyContinue) {
            try { Invoke-AthenaVoice -Text $response -Silent } catch {}
        }
    }
}

# ====================================================================
# ðŸ”§ Export global
# ====================================================================
Export-ModuleMember -Function Invoke-AthenaConversant
Write-Host "âœ… Athena.Conversant.psm1 v3.6-AutoClean-Stable chargÃ© (crÃ©ation automatique + nettoyage Markdown + feedback vocal)." -ForegroundColor Cyan





































