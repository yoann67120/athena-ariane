# ====================================================================
# 🧹 ARIANE V4 - AutoCleanup
# Phase 7.7 - Nettoyage automatique des anciens fichiers
# Auteur : Yoann Rousselle
# ====================================================================

$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$logFile = "C:\Ariane-Agent\logs\Global.log"

function Write-Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [AUTOCLEANUP] $msg"
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

Write-Log "=== DÉBUT DU CYCLE AUTO CLEANUP ==="

# --- CONFIGURATION ---
$SnapshotsDir = "C:\Ariane-Agent\Backups\ArianeV4_Snapshots"
$LogsDir = "C:\Ariane-Agent\logs"

$SnapshotRetentionDays = 7
$LogRetentionDays = 15

# --- FONCTION GÉNÉRIQUE ---
function Cleanup-OldFiles($path, $days, $type) {
    $limit = (Get-Date).AddDays(-$days)
    if (Test-Path $path) {
        $files = Get-ChildItem -Path $path -File -Recurse | Where-Object { $_.LastWriteTime -lt $limit }
        foreach ($file in $files) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                Write-Log "🧩 Supprimé ($type) : $($file.FullName)"
            } catch {
                Write-Log "⚠️ Erreur suppression ($type) : $($file.FullName) - $($_.Exception.Message)"
            }
        }
        Write-Log "✅ Nettoyage terminé pour $type → $($files.Count) fichier(s) supprimé(s)."
    } else {
        Write-Log "⚠️ Dossier introuvable : $path"
    }
}

# --- NETTOYAGE ---
Cleanup-OldFiles -path $SnapshotsDir -days $SnapshotRetentionDays -type "Snapshot"
Cleanup-OldFiles -path $LogsDir -days $LogRetentionDays -type "Log"

Write-Log "=== FIN DU CYCLE AUTO CLEANUP ===`n"
