# ====================================================================
# 🚀 Start-NgrokBridge.ps1
# Description : Lance l’Usine à Projets (Flask + AgentKit) et Ngrok
# Journalise automatiquement l’URL publique et l’état de connexion
# ====================================================================

# --- Configuration de base ---
$UsinePath = "C:\Ariane-Agent\UsineAProjets\usine_server.py"
$NgrokPath = "C:\ngrok\ngrok.exe"
$LogDir    = "C:\Ariane-Agent\logs"
$BridgeLog = Join-Path $LogDir "BridgeMonitor.log"
$BridgeStatus = Join-Path $LogDir "BridgeStatus.json"
$Port = 5050

# --- Vérification des répertoires ---
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

# --- Fonction de journalisation ---
function Write-BridgeLog($msg, [string]$color="Yellow") {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $msg"
    $line | Out-File -FilePath $BridgeLog -Append -Encoding utf8
    Write-Host $line -ForegroundColor $color
}

# --- Vérifie si Flask tourne déjà ---
$flask = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*python*" -and $_.StartInfo.Arguments -like "*usine_server.py*" }

if (-not $flask) {
    Write-BridgeLog "🧩 Démarrage du serveur Flask (Usine à Projets)…" "Cyan"
    Start-Process "python" "-u `"$UsinePath`"" -WindowStyle Minimized
    Start-Sleep -Seconds 5
} else {
    Write-BridgeLog "✅ Serveur Flask déjà actif." "Green"
}

# --- Lancement de Ngrok ---
Write-BridgeLog "🌐 Lancement de Ngrok (port $Port)…" "Cyan"
Start-Process $NgrokPath "http $Port --log=stdout" -WindowStyle Minimized
Start-Sleep -Seconds 7

# --- Récupération de l’URL publique ---
try {
    $apiUrl = "http://127.0.0.1:4040/api/tunnels"
    $resp = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
    $publicUrl = ($resp.tunnels | Where-Object { $_.proto -eq "https" }).public_url
    if ($publicUrl) {
        Write-BridgeLog "✅ Tunnel Ngrok actif : $publicUrl" "Green"
        $status = @{
            status = "online"
            timestamp = (Get-Date).ToString("s")
            url = $publicUrl
            port = $Port
            mode = "secure"
        }
        $status | ConvertTo-Json | Out-File -FilePath $BridgeStatus -Encoding utf8
    } else {
        throw "Aucune URL publique trouvée"
    }
}
catch {
    Write-BridgeLog "❌ Impossible de récupérer l’URL Ngrok : $_" "Red"
}

Write-BridgeLog "🧠 Pont GPT-5 ↔ Usine prêt." "Green"
Write-BridgeLog "Détails enregistrés dans $BridgeStatus" "DarkGray"
