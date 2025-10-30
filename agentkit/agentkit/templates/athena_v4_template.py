import os, json, datetime
ATHENA_ROOT = r"C:\Users\Sonia\Dropbox\ArianeV4"
STRUCTURE = {
    "Modules": ["Athena.Engine.psm1","Athena.Logger.psm1","Athena.Memory.psm1"],
    "Scripts": ["Start-Athena.ps1","Athena.AutoRepair.ps1","Athena.CheckIntegrity.ps1"],
    "Memory": ["Athena.Memory.json","EmotionState.json","LearningHistory.json"],
    "Logs": [], "WebUI": ["index.html","style.css","script.js"],
    "WebUI/assets": [], "Config": ["settings.json","paths.json","version.txt"]
}
def write(path,content=""): os.makedirs(os.path.dirname(path),exist_ok=True); open(path,"w",encoding="utf-8").write(content)
def create_athena_v4():
    print(f"🧩 Création complète d’Athena V4 dans {ATHENA_ROOT}")
    os.makedirs(ATHENA_ROOT,exist_ok=True)
    for folder,files in STRUCTURE.items():
        path=os.path.join(ATHENA_ROOT,folder); os.makedirs(path,exist_ok=True)
        [write(os.path.join(path,f)) for f in files]
    meta={"project":"AthenaV4","author":"Yoann Rousselle","created_at":datetime.datetime.now().isoformat(),"version":"1.0","description":"Agent local autonome généré par l’Usine à Projets","status":"Initialized"}
    write(os.path.join(ATHENA_ROOT,"meta.json"),json.dumps(meta,indent=4,ensure_ascii=False))
    settings={"agent_name":"AthenaV4","language":"fr-FR","log_path":os.path.join(ATHENA_ROOT,"Logs"),"memory_path":os.path.join(ATHENA_ROOT,"Memory"),"mode":"autonome","created_by":"Usine à Projets"}
    write(os.path.join(ATHENA_ROOT,"Config","settings.json"),json.dumps(settings,indent=4,ensure_ascii=False))
    write(os.path.join(ATHENA_ROOT,"Config","paths.json"),json.dumps({"modules":os.path.join(ATHENA_ROOT,"Modules"),"scripts":os.path.join(ATHENA_ROOT,"Scripts"),"webui":os.path.join(ATHENA_ROOT,"WebUI")},indent=4))
    write(os.path.join(ATHENA_ROOT,"Config","version.txt"),"Athena V4 – v1.0\n")
    start_ps1 = """Write-Host '🧠 Démarrage complet d’Athena V4...' -ForegroundColor Cyan
$base = Split-Path -Parent $MyInvocation.MyCommand.Definition
Import-Module "$base\\..\\Modules\\Athena.Engine.psm1" -Force -Global
Start-Sleep -Seconds 1
Write-Host '✅ Athena V4 initialisée avec succès.' -ForegroundColor Green"""
    write(os.path.join(ATHENA_ROOT,"Scripts","Start-Athena.ps1"),start_ps1)
    engine="function Start-AthenaEngine {Write-Host '🔧 Initialisation du moteur Athena...' -ForegroundColor Yellow; 'Athena Engine prêt.'}; Export-ModuleMember -Function Start-AthenaEngine"
    write(os.path.join(ATHENA_ROOT,"Modules","Athena.Engine.psm1"),engine)
    write(os.path.join(ATHENA_ROOT,"WebUI","index.html"),"<html><body><h1>Athena V4 Interface</h1></body></html>")
    write(os.path.join(ATHENA_ROOT,"WebUI","style.css"),"body{background:#111;color:#0ff;font-family:Arial}")
    write(os.path.join(ATHENA_ROOT,"WebUI","script.js"),"console.log('Athena V4 WebUI ready');")
    print("✅ Athena V4 – Création complète terminée."); return {"status":"ok","path":ATHENA_ROOT}
def run(params=None): return create_athena_v4()
if __name__=="__main__": create_athena_v4()
