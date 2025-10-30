<#
.SYNOPSIS
  Corrige la structure, l'encodage et les exports de tous les modules Ariane (.psm1)

.DESCRIPTION
  - Déplace chaque module dans un dossier qui porte son nom
  - Vérifie et ajoute Export-ModuleMember si manquant
  - Corrige l’encodage en UTF-8 sans BOM
  - Génère un rapport JSON pour l’Agent local

.AUTEUR
  Ariane System - GPT Integration Engine
#>

param(
    [string]$ModulesRoot = "C:\Users\Sonia\Dropbox\ArianeV4\Modules",
    [string]$ReportPath = "C:\Ariane-Agent\logs\FixModules_Report.json"
)

Write-Host "🔍 Démarrage de la vérification des modules Ariane..." -ForegroundColor Cyan

$results = @()

# S'assurer que les dossiers existent
if (-not (Test-Path $ModulesRoot)) {
    Write-Host "❌ Dossier introuvable : $ModulesRoot" -ForegroundColor Red
    exit
}
if (-not (Test-Path (Split-Path $ReportPath))) {
    New-Item -ItemType Directory -Path (Split-Path $ReportPath) -Force | Out-Null
}

# Scanner les fichiers .psm1
$modules = Get-ChildItem -Path $ModulesRoot -Recurse -Filter "*.psm1"

foreach ($m in $modules) {
    try {
        $status = [ordered]@{
            Module = $m.BaseName
            Path = $m.FullName
            Fixed = $false
            ExportAdded = $false
            EncodingFixed = $false
            FolderFixed = $false
            Errors = @()
        }

        # Vérifier si le fichier est bien dans un dossier qui porte son nom
        $expectedFolder = Join-Path $ModulesRoot $m.BaseName
        $expectedPath = Join-Path $expectedFolder ($m.BaseName + ".psm1")

        if ($m.DirectoryName -ne $expectedFolder) {
            Write-Host "🧩 Réorganisation : $($m.Name)" -ForegroundColor Yellow
            New-Item -ItemType Directory -Force -Path $expectedFolder | Out-Null
            Move-Item -Path $m.FullName -Destination $expectedPath -Force
            $status["FolderFixed"] = $true
        }

        # Lire le contenu et corriger encodage
        $content = Get-Content -Raw -Path $expectedPath -Encoding UTF8
        Set-Content -Path $expectedPath -Value $content -Encoding utf8
        $status["EncodingFixed"] = $true

        # Vérifier la présence d'un Export-ModuleMember
        if ($content -notmatch "Export-ModuleMember") {
            Write-Host "⚙️  Export-ModuleMember ajouté dans $($m.Name)" -ForegroundColor Yellow
            $funcs = ($content | Select-String -Pattern "function\s+([A-Za-z0-9_-]+)" -AllMatches).Matches.Groups[1].Value
            if ($funcs.Count -gt 0) {
                $exportLine = "`nExport-ModuleMember -Function " + ($funcs -join ', ')
                Add-Content -Path $expectedPath -Value $exportLine
                $status["ExportAdded"] = $true
            }
        }

        $status["Fixed"] = $true
        $results += $status

    } catch {
        $status["Errors"] += $_.Exception.Message
        $results += $status
    }
}

# Génération du rapport JSON
$json = $results | ConvertTo-Json -Depth 4 | Out-String
Set-Content -Path $ReportPath -Value $json -Encoding utf8

Write-Host "`n✅ Vérification terminée !" -ForegroundColor Green
Write-Host "📄 Rapport disponible ici : $ReportPath" -ForegroundColor Gray

$okCount = ($results | Where-Object { $_.Fixed -eq $true }).Count
$warnCount = ($results | Where-Object { $_.Errors.Count -gt 0 }).Count
$exportAdded = ($results | Where-Object { $_.ExportAdded -eq $true }).Count

Write-Host "--------------------------------------------"
Write-Host "🟢 Modules valides : $okCount"
Write-Host "🟡 Export ajoutés : $exportAdded"
Write-Host "🔴 Modules avec erreurs : $warnCount"
Write-Host "--------------------------------------------"

return $results
