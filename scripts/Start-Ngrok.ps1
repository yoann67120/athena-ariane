# ====================================================================
# 🚀 ARIANE V4 - START NGROK (v1)
# Auteur : Yoann Rousselle
# Description : Démarrage automatique des tunnels ngrok permanents
# ====================================================================

$ErrorActionPreference = "Stop"
$NgrokPath = "C:\Ariane-Agent\Tools\ngrok.exe"
$ConfigPath = "C:\Ariane-Agent\Tools\ngrok.yml"
$LogFile = "C:\Ariane-Agent\logs\Ngrok.log"

# Création du dossier de logs
if (!(Test-Path (Split-Path $LogFile))) {
    New-Item -ItemType Directory -Force -Path (Split-Path $LogFile) | Out-Null
}

function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $msg" | Tee-Object -FilePath $LogFile -Append
}

try {
    Log "==========================================="
    Log "🚀 Lancement des tunnels ngrok (Ariane + Usine)"
    Log "==========================================="

    # Vérification de ngrok
    if (!(Test-Path $NgrokPath)) {
        Log "❌ ngrok non trouvé à $NgrokPath"
        exit 1
    }

    # Démarrage des tunnels
    Start-Process -FilePath $NgrokPath -ArgumentList "start --all --config `"$ConfigPath`"" -WindowStyle Hidden
    Start-Sleep -Seconds 5

    Log "✅ Tunnels ngrok lancés via configuration : $ConfigPath"

    # Vérification en ligne
    $check = curl.exe -s https://ariane.ngrok.io/bridge/sync -H "Content-Type: application/json" -d "{}"
    if ($check -match "received") {
        Log "🟢 Bridge en ligne sur https://ariane.ngrok.io"
    } else {
        Log "⚠️ Impossible de contacter le Bridge (port 5075)"
    }

    Log "🟢 Usine en ligne sur https://usine.ngrok.io"
    Log "=== Fin du démarrage Ngrok ==="
}
catch {
    Log "❌ Erreur : $($_.Exception.Message)"
}
