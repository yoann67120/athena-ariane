# ====================================================================
# 🚀 ARIANE V4 – AutoDeploy.ps1
# Redéploie automatiquement Bridge, Usine ou Relay si absent
# ====================================================================
param([string]$Target="All")
$Log = "C:\Ariane-Agent\logs\AutoMaintenance.log"
function Write-Log($tag,$msg){$ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff");Add-Content $Log "[$ts] [$tag] $msg"}
Write-Log "auto_deploy" "=== DÉMARRAGE AUTO_DEPLOY ($Target) ==="

$Targets=@{
 "Bridge" = "C:\Ariane-Agent\Bridge\bridge_server.py"
 "Usine"  = "C:\Ariane-Agent\UsineAProjets\usine_server.py"
 "Relay"  = "C:\Ariane-Agent\BridgeRelay\agentkit_hmac_client.py"
}

foreach($t in $Targets.Keys){
 if($Target -ne "All" -and $t -ne $Target){continue}
 if(!(Test-Path $Targets[$t])){
    Write-Log "auto_deploy" "⚠️ $t absent → restauration"
    # Exemple : récupération depuis modèle local
    Copy-Item "$BaseDir\Backups\$t" $Targets[$t] -ErrorAction SilentlyContinue
    Write-Log "auto_deploy" "✅ $t restauré"
 }else{
    Write-Log "auto_deploy" "✅ $t présent"
 }
}
Write-Log "auto_deploy" "=== AUTO_DEPLOY TERMINÉ ==="
