# ====================================================================
# ðŸ¤– Athena.HybridCore.psm1 â€“ CÅ“ur cognitif hybride prÃ©dictif
# Version : v1.5 â€“ GPT-Only Stable
# Auteur  : Ariane V4 / Athena Core Engine
# Description :
#   Ce module assure lâ€™analyse cognitive et le routage IA.
#   Dans cette version, tout est routÃ© directement vers GPT
#   pour stabiliser la communication et Ã©viter les erreurs Ollama.
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# === DÃ©pendances ===
if (-not (Get-Command Invoke-LocalModel -ErrorAction SilentlyContinue)) {
    Import-Module "$PSScriptRoot\LocalModel.psm1" -Force -Global
}
if (-not (Get-Command Invoke-OpenAIRequest -ErrorAction SilentlyContinue)) {
    Import-Module "$PSScriptRoot\Core.psm1" -Force -Global
}

# === RÃ©pertoires mÃ©moire ===
$Root = Split-Path -Parent $PSScriptRoot
$MemoryDir = Join-Path $Root "Memory"
if (!(Test-Path $MemoryDir)) { New-Item -ItemType Directory -Path $MemoryDir | Out-Null }

$HistoryFile  = Join-Path $MemoryDir "HybridHistory.json"
$MetricsFile  = Join-Path $MemoryDir "HybridMetrics.json"
$ProfileFile  = Join-Path $MemoryDir "HybridProfile.json"

foreach ($file in @($HistoryFile,$MetricsFile,$ProfileFile)) {
    if (!(Test-Path $file)) { "[]" | Out-File $file -Encoding utf8 }
}

# ====================================================================
# ðŸ§  Analyse linguistique du style utilisateur
# ====================================================================
function Get-PromptProfile {
    param([string]$Text)
    $len   = $Text.Length
    $words = ($Text -split "\s+").Count
    $quest = ($Text -match "\?$")
    $excl  = ($Text -match "\!$")
    $verbs = ([regex]::Matches($Text,"(er|ir|re|Ã©|Ã©e|Ã©s|ait|ait-il)")).Count

    $scoreComplex = [math]::Round(($len + $verbs) / 50, 2)
    $scoreEmotion = if ($excl) {0.9} elseif ($quest) {0.6} else {0.3}

    return [PSCustomObject]@{
        Length   = $len
        Words    = $words
        Emotion  = $scoreEmotion
        Complex  = $scoreComplex
        Type     = if ($scoreComplex -gt 2.5) {"technique"} elseif ($scoreEmotion -gt 0.6) {"Ã©motionnel"} else {"neutre"}
    }
}

# ====================================================================
# ðŸ§  Fonction principale â€“ Invoke-AthenaHybrid (GPT Only)
# ====================================================================
function Invoke-AthenaHybrid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Prompt
    )

    Write-Host "`nðŸ§  [Hybrid] Analyse cognitive du prompt..." -ForegroundColor Cyan
    $profile = Get-PromptProfile -Text $Prompt
    Write-Host ("   â†’ Type dÃ©tectÃ© : " + $profile.Type + " | Longueur=" + $profile.Length + " | Emotion=" + $profile.Emotion) -ForegroundColor DarkGray

    # ðŸ”’ ForÃ§age permanent du moteur GPT
    Write-Host "ðŸ”µ [Hybrid] Mode verrouillÃ© : routage GPT uniquement" -ForegroundColor Blue
    try {
        $response = Invoke-OpenAIRequest -Prompt $Prompt
        $engine = "GPT-4"
    } catch {
        Write-Warning "âš ï¸ GPT indisponible. Aucun fallback local autorisÃ© dans cette version."
        $response = "Erreur : GPT non accessible pour le moment."
        $engine = "Erreur"
    }

    # Nettoyage / affichage
    if ($response -is [string]) { $final = $response } else {
        try { $final = ($response | ConvertFrom-Json -ErrorAction Stop).response }
        catch { $final = $response | Out-String }
    }

    $tag   = if ($engine -match "GPT") { "[GPT]" } else { "[ERREUR]" }
    $color = if ($engine -match "GPT") { "Blue" } else { "Red" }
    Write-Host "ðŸ¤– $tag $final" -ForegroundColor $color

    # Sauvegarde historique
    $entry = [PSCustomObject]@{
        Date     = (Get-Date)
        Engine   = $engine
        Profile  = $profile
        Prompt   = $Prompt
        Response = $final
    }
    $hist = Get-Content $HistoryFile | ConvertFrom-Json
    $hist += $entry
    $hist | ConvertTo-Json -Depth 6 | Out-File $HistoryFile -Encoding utf8

    # Sauvegarde des mÃ©triques (GPT only)
    $metrics = @{
        LocalCount    = 0
        GPTCount      = ($hist | Where-Object {$_.Engine -match "GPT"}).Count
        AccuracyScore = 1
    }
    $metrics | ConvertTo-Json | Out-File $MetricsFile -Encoding utf8

    # Mise Ã  jour profil utilisateur
    $profiles = if ((Get-Content $ProfileFile) -ne $null) { Get-Content $ProfileFile | ConvertFrom-Json } else { @() }
    $profiles += $profile
    $profiles | ConvertTo-Json -Depth 4 | Out-File $ProfileFile -Encoding utf8

    return $final
}

# ====================================================================
# ðŸ§© Fonction dâ€™analyse du profil utilisateur
# ====================================================================
function Invoke-AthenaHybridProfile {
    if (!(Test-Path $ProfileFile)) { Write-Host "Aucun profil trouvÃ©." -ForegroundColor Red; return }
    $data = Get-Content $ProfileFile | ConvertFrom-Json
    $avgLen  = [math]::Round(($data.Length | Measure-Object -Average).Average,1)
    $avgEmo  = [math]::Round(($data.Emotion | Measure-Object -Average).Average,2)
    $types   = $data.Type | Group-Object | Sort-Object Count -Descending

    Write-Host "`nðŸ“Š Profil utilisateur dâ€™Athena :" -ForegroundColor Cyan
    Write-Host "   Moyenne longueur phrase : $avgLen caractÃ¨res"
    Write-Host "   Moyenne Ã©motion dÃ©tectÃ©e : $avgEmo"
    Write-Host "   RÃ©partition des types :" 
    foreach ($t in $types) { Write-Host "     â€¢ $($t.Name) â†’ $($t.Count) prompts" }
}

# ====================================================================
# ðŸ”§ Export global
# ====================================================================
Export-ModuleMember -Function Invoke-AthenaHybrid, Invoke-AthenaHybridProfile
Write-Host "âœ… Athena.HybridCore v1.5 GPT-Only-Stable chargÃ© (routage 100% GPT, sans fallback Ollama)." -ForegroundColor Cyan




