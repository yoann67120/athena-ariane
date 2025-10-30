# ====================================================================
# 🕒 ARIANE V4 - AutoBackup & SelfCheck
# Phase 7.6 - Exécution automatique quotidienne (03h00)
# Auteur : Yoann Rousselle
# ====================================================================

$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$logFile = "C:\Ariane-Agent\logs\Global.log"

function Write-Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [AUTOBACKUP] $msg"
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

Write-Log "=== DÉBUT DU CYCLE AUTO BACKUP & SELFCHECK ==="

# 1️⃣ Vérification des services de base
try {
    $services = @(
        @{ Name = "Usine Flask"; Url = "http://localhost:5050/" },
        @{ Name = "AgentKit /list"; Url = "http://localhost:5050/list" },
        @{ Name = "Cockpit Athena"; Url = "http://localhost:5070/health" },
        @{ Name = "Bridge GPT"; Url = "http://localhost:5000/execute" }
    )

    foreach ($srv in $services) {
        try {
            $resp = Invoke-RestMethod -Uri $srv.Url -Method Get -TimeoutSec 5
            Write-Log "✅ $($srv.Name) : OK"
        } catch {
            Write-Log "❌ $($srv.Name) : Inaccessible ($($_.Exception.Message))"
        }
    }
} catch {
    Write-Log "⚠️ Erreur pendant la vérification réseau : $_"
}

# 2️⃣ Snapshot automatique
try {
    Write-Log "📦 Lancement du Snapshot automatique..."
    python "C:\Ariane-Agent\Tests\SnapshotArianeV4.py" | Out-Null
    Write-Log "✅ Snapshot terminé avec succès."
} catch {
    Write-Log "❌ Erreur durant le Snapshot : $_"
}

# 3️⃣ Rapport de validation
try {
    Write-Log "🧠 Génération du rapport de validation..."
    python "C:\Ariane-Agent\Tests\GenerateValidationReport.py" | Out-Null
    Write-Log "✅ Rapport de validation mis à jour."
} catch {
    Write-Log "❌ Erreur durant la génération du rapport : $_"
}

Write-Log "=== FIN DU CYCLE AUTO BACKUP & SELFCHECK ===`n"
