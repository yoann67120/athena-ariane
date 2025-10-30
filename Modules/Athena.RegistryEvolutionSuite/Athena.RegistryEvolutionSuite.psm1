# ====================================================================
# ðŸ§  Athena.RegistryEvolutionSuite.psm1 â€“ v1.0-CoreFusion-Evo
# --------------------------------------------------------------------
# Objectif :
#   Cerveau Ã©volutif du registre open-source dâ€™Athena.
#   RÃ©unit toutes les fonctions d'analyse, apprentissage et visualisation
#   utilisÃ©es entre les Phases 36 â†’ 40.
# --------------------------------------------------------------------
# Auteur  : Yoann Rousselle / Athena Core
# Date    : 2025-10-17
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === RÃ©pertoires standard ===
$ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir    = Split-Path -Parent $ModuleRoot
$LogsDir    = Join-Path $RootDir "Logs"
$MemoryDir  = Join-Path $RootDir "Memory"
$ConfigDir  = Join-Path $RootDir "Config"
$Registry   = Join-Path $ConfigDir "OpenSourceRegistry.json"
$PlanFile   = Join-Path $MemoryDir "EvolutionPlans.json"
$LogFile    = Join-Path $LogsDir "RegistryEvolution.log"
$BackupDir  = Join-Path $MemoryDir "Archives\Registry"

foreach ($p in @($LogsDir,$MemoryDir,$ConfigDir,$BackupDir)) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# === Journal interne ===
function Write-RegistryLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

# ====================================================================
# 1ï¸âƒ£ Ã‰valuation des intÃ©grations rÃ©ussies
# ====================================================================
function Evaluate-IntegrationSuccess {
    <#
        Analyse les intÃ©grations planifiÃ©es et dÃ©tecte celles qui ont
        rÃ©ellement Ã©tÃ© utilisÃ©es avec succÃ¨s dans les logs dâ€™Athena.
        Marque ces intÃ©grations comme "ValidÃ©e âœ”" dans EvolutionPlans.json.
    #>
    Write-RegistryLog "Ã‰valuation des intÃ©grations en cours..."
    if (!(Test-Path $PlanFile)) { return }

    $plans = Get-Content $PlanFile -Raw | ConvertFrom-Json
    foreach ($p in $plans) {
        if ($p.Statut -eq "ProposÃ©") {
            # Exemple : validation simple si prÃ©sence du nom dans IntegrationAdvisor.log
            $match = Select-String -Path "$LogsDir\IntegrationAdvisor.log" -Pattern $p.Integration -Quiet
            if ($match) {
                $p.Statut = "ValidÃ©e âœ”"
                Write-RegistryLog "âœ… $($p.Integration) validÃ©e automatiquement."
            }
        }
    }

    $plans | ConvertTo-Json -Depth 4 | Out-File $PlanFile -Encoding utf8
    Write-RegistryLog "Mise Ã  jour du plan dâ€™Ã©volution terminÃ©e."
}

# ====================================================================
# 2ï¸âƒ£ Apprentissage des outils prÃ©fÃ©rÃ©s
# ====================================================================
function Learn-PreferredTools {
    <#
        Compte le nombre dâ€™occurrences de chaque intÃ©gration validÃ©e et
        enregistre les plus utilisÃ©es dans Memory\PreferredTools.json.
    #>
    Write-RegistryLog "Apprentissage des outils prÃ©fÃ©rÃ©s..."
    if (!(Test-Path $PlanFile)) { return }

    $plans = Get-Content $PlanFile -Raw | ConvertFrom-Json
    $used  = $plans | Where-Object { $_.Statut -eq "ValidÃ©e âœ”" } | Group-Object Integration | Sort-Object Count -Descending
    $pref  = @()
    foreach ($u in $used) {
        $pref += [pscustomobject]@{ Tool = $u.Name; Usage = $u.Count }
    }

    $prefFile = Join-Path $MemoryDir "PreferredTools.json"
    $pref | ConvertTo-Json -Depth 4 | Out-File $prefFile -Encoding utf8
    Write-RegistryLog "Outils prÃ©fÃ©rÃ©s mis Ã  jour ($($pref.Count) entrÃ©es)."
}

# ====================================================================
# 3ï¸âƒ£ Expansion automatique du registre
# ====================================================================
function Auto-ExpandRegistry {
    <#
        Appelle Athena.AutoExpandRegistry.psm1 pour enrichir le registre
        avec les mots-clÃ©s manquants dÃ©tectÃ©s dans les contextes rÃ©cents.
    #>
    Write-RegistryLog "Appel Ã  AutoExpandRegistry..."
    $autoModule = Join-Path $ModuleRoot "Athena.AutoExpandRegistry.psm1"
    if (Test-Path $autoModule) {
        Import-Module $autoModule -Force -Global
        Invoke-AutoExpandRegistry -Contexts @(
            "assistant vocal local",
            "base de donnÃ©es locale",
            "supervision systÃ¨me",
            "automatisation de workflow",
            "intelligence artificielle autonome"
        )
    } else {
        Write-RegistryLog "âŒ Module AutoExpandRegistry introuvable." "ERROR"
    }
}

# ====================================================================
# 4ï¸âƒ£ DÃ©couverte des IA locales / endpoints
# ====================================================================
function Discover-AIEndpoints {
    <#
        Scanne le rÃ©seau local (localhost et ports communs) pour dÃ©tecter
        les services IA actifs : Ollama, LM Studio, AutoGPT, TextGenWebUI.
        Enregistre la liste dans Memory\DetectedAI.json.
    #>
    Write-RegistryLog "DÃ©couverte des IA locales..."
    $ports = @(11434, 5000, 7860, 8080)
    $found = @()

    foreach ($p in $ports) {
        try {
            $tcp = New-Object Net.Sockets.TcpClient
            $async = $tcp.BeginConnect("localhost", $p, $null, $null)
            $success = $async.AsyncWaitHandle.WaitOne(300)
            if ($success -and $tcp.Connected) {
                $found += [pscustomobject]@{ Port=$p; Service="Possible IA (port $p)"; Status="Open" }
                Write-RegistryLog "ðŸ”Ž Port $p dÃ©tectÃ© comme ouvert (IA possible)."
            }
            $tcp.Close()
        } catch {}
    }

    $file = Join-Path $MemoryDir "DetectedAI.json"
    $found | ConvertTo-Json -Depth 3 | Out-File $file -Encoding utf8
    Write-RegistryLog "DÃ©tection IA terminÃ©e ($($found.Count) services)."
}

# ====================================================================
# 5ï¸âƒ£ Visualisation de la carte dâ€™intÃ©gration
# ====================================================================
function Visualize-IntegrationMap {
    <#
        CrÃ©e un fichier HTML basique affichant les intÃ©grations et IA dÃ©tectÃ©es,
        utilisÃ© par le Cockpit pour visualiser le rÃ©seau cognitif dâ€™Athena.
    #>
    Write-RegistryLog "GÃ©nÃ©ration de la carte dâ€™intÃ©gration..."
    $prefFile = Join-Path $MemoryDir "PreferredTools.json"
    $aiFile   = Join-Path $MemoryDir "DetectedAI.json"

    $pref = @(); $ai = @()
    if (Test-Path $prefFile) { $pref = Get-Content $prefFile -Raw | ConvertFrom-Json }
    if (Test-Path $aiFile)   { $ai   = Get-Content $aiFile -Raw | ConvertFrom-Json }

    $html = @()
    $html += "<html><head><title>Athena Integration Map</title></head><body style='font-family:Segoe UI;background:#111;color:#eee;'>"
    $html += "<h2>ðŸ§  Athena Integration Map</h2><h3>Outils prÃ©fÃ©rÃ©s</h3><ul>"
    foreach ($p in $pref) { $html += "<li>$($p.Tool) â€“ utilisÃ© $($p.Usage)x</li>" }
    $html += "</ul><h3>IA dÃ©tectÃ©es</h3><ul>"
    foreach ($a in $ai) { $html += "<li>$($a.Service) ($($a.Port))</li>" }
    $html += "</ul></body></html>"

    $file = Join-Path $RootDir "WebUI\IntegrationMap.html"
    $html -join "`n" | Out-File $file -Encoding utf8
    Write-RegistryLog "Carte dâ€™intÃ©gration gÃ©nÃ©rÃ©e : $file"
}

# ====================================================================
# 6ï¸âƒ£ Synchronisation avec registres externes (GitHub / Cloud)
# ====================================================================
function Sync-RegistryCloud {
    <#
        TÃ©lÃ©charge ou met Ã  jour automatiquement des registres publics
        (GitHub, HuggingFace, etc.) pour enrichir OpenSourceRegistry.json.
    #>
    Write-RegistryLog "Synchronisation du registre open-source (mode simulÃ©)."
    # Simulation pour version locale : en Phase 38, connexion rÃ©seau rÃ©elle
    Write-RegistryLog "âœ” Synchronisation terminÃ©e (simulation)."
}

# ====================================================================
# 7ï¸âƒ£ PrÃ©diction des outils futurs
# ====================================================================
function Predict-FutureTools {
    <#
        Analyse les logs pour identifier les outils Ã©mergents ou rÃ©currents.
        Produit un fichier FutureTools.json avec suggestions dâ€™intÃ©gration.
    #>
    Write-RegistryLog "Analyse prÃ©dictive des futurs outils..."
    $lines = Get-Content $LogFile -ErrorAction SilentlyContinue
    $freq  = $lines | Select-String -Pattern 'Ajout du mot-clÃ©' | Group-Object | Sort-Object Count -Descending
    $pred  = @()
    foreach ($f in $freq | Select-Object -First 5) {
        $pred += [pscustomobject]@{ MotCle=$f.Name; Occurrences=$f.Count }
    }

    $file = Join-Path $MemoryDir "FutureTools.json"
    $pred | ConvertTo-Json -Depth 4 | Out-File $file -Encoding utf8
    Write-RegistryLog "Fichier FutureTools.json mis Ã  jour."
}

# ====================================================================
# 8ï¸âƒ£ RÃ©organisation et nettoyage du registre
# ====================================================================
function Refactor-Registry {
    <#
        Supprime les doublons et reconstruit proprement le fichier JSON
        OpenSourceRegistry.json tout en conservant les sauvegardes.
    #>
    Write-RegistryLog "Nettoyage du registre open-source..."
    if (!(Test-Path $Registry)) { return }

    $backup = Join-Path $BackupDir ("Refactor_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")
    Copy-Item $Registry $backup -Force

    $reg = Get-Content $Registry -Raw | ConvertFrom-Json
    foreach ($section in $reg.PSObject.Properties.Name) {
        foreach ($tool in $reg.$section.PSObject.Properties.Name) {
            $entry = $reg.$section.$tool
            $entry.keywords = $entry.keywords | Sort-Object -Unique
        }
    }

    $reg | ConvertTo-Json -Depth 6 | Out-File $Registry -Encoding utf8
    Write-RegistryLog "âœ… Registre nettoyÃ© et restructurÃ©."
}

# ====================================================================
# ðŸ”š Exports publics
# ====================================================================
Export-ModuleMember -Function `
    Evaluate-IntegrationSuccess, `
    Learn-PreferredTools, `
    Auto-ExpandRegistry, `
    Discover-AIEndpoints, `
    Visualize-IntegrationMap, `
    Sync-RegistryCloud, `
    Predict-FutureTools, `
    Refactor-Registry

Write-Host "ðŸ§  Module Athena.RegistryEvolutionSuite.psm1 chargÃ© (v1.0-CoreFusion-Evo)." -ForegroundColor Cyan
Write-RegistryLog "Module CoreFusion-Evo v1.0 chargÃ© â€“ Phases 36 â†’ 40 prÃªtes."



