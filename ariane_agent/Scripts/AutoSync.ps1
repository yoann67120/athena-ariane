# ====================================================================
# 🚀 ARIANE V4 – AutoSync.ps1
# Vérifie intégrité Bridge / Usine / Tunnel + relance si besoin
# ====================================================================
param([string]$Mode="quick")
$Log = "C:\Ariane-Agent\logs\AutoMaintenance.log"
function Write-Log($tag,$msg){$ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff");Add-Content $Log "[$ts] [$tag] $msg"}
Write-Log "sync_cloud" "=== DÉMARRAGE SYNC_CLOUD ($Mode) ==="

$Bridge="C:\Ariane-Agent\Bridge\bridge_server.py"
$Usine ="C:\Ariane-Agent\UsineAProjets\usine_server.py"
$Ngrok ="C:\Ariane-Agent\Tools\ngrok.exe"

if (!(Test-Path $Bridge)){Write-Log "sync_cloud" "❌ Bridge manquant → relance système";& "$env:ComSpec" /c "powershell -ExecutionPolicy Bypass -File C:\Ariane-Agent\Scripts\Start-AgentSystem.ps1";exit}
if (!(Test-Path $Usine)){Write-Log "sync_cloud" "❌ Usine manquante → redéploiement";& "$ScriptDir\AutoDeploy.ps1" -Target "Usine";exit}
if (!(Test-Path $Ngrok)){Write-Log "sync_cloud" "⚠️ ngrok absent → télécharger manuellement";exit}

# Vérifie que le tunnel répond
try{
    $resp=Invoke-RestMethod -Uri "http://127.0.0.1:4040/api/tunnels" -TimeoutSec 3 -ErrorAction Stop
    Write-Log "sync_cloud" "✅ Tunnel actif ($($resp.tunnels[0].public_url))"
}catch{Write-Log "sync_cloud" "Tunnel inactif - relance"; & "$Ngrok" http 5075 | Out-Null}

Write-Log "sync_cloud" "✅ Vérification OK"
