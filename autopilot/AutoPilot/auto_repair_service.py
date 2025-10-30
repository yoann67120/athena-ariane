# ====================================================================
# 🩺 AutoRepair Service – Phase 14.2
# Vérifie l’intégrité des fichiers et les restaure si nécessaire
# ====================================================================

import os, hashlib, datetime, shutil, json

LOG_PATH = r"C:\\Ariane-Agent\\logs\\autorepair.log"
CRITICAL_FILES = {
    "BridgeSecure.ps1": r"C:\\Ariane-Agent\\Scripts\\Invoke-BridgeSecure.ps1",
    "Invoke-AgentSecure.py": r"C:\\Ariane-Agent\\Scripts\\Invoke-AgentSecure.py",
    "autopilot_server.py": r"C:\\Ariane-Agent\\AutoPilot\\autopilot_server.py",
    "supervisor_service.py": r"C:\\Ariane-Agent\\AutoPilot\\supervisor_service.py",
    "agent_registry.py": r"C:\\Ariane-Agent\\agentkit\\agent_registry.py"
}

def log(msg):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    with open(LOG_PATH,"a",encoding="utf-8") as f: f.write(line+"\\n")

def sha256sum(path):
    try:
        h = hashlib.sha256()
        with open(path,"rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                h.update(chunk)
        return h.hexdigest()
    except FileNotFoundError:
        return None

def verify_and_repair():
    summary = {}
    for name, path in CRITICAL_FILES.items():
        ref_path = os.path.join(r"C:\\Ariane-Agent\\UsineAProjets\\templates\\AthenaV4", "Scripts" if path.endswith(".ps1") else "Modules")
        ref_candidate = None
        # Cherche une copie de secours dans tout Ariane-Agent
        for root,dirs,files in os.walk(r"C:\\Ariane-Agent"):
            for f in files:
                if f == name:
                    ref_candidate = os.path.join(root,f)
                    break
            if ref_candidate: break

        hash_value = sha256sum(path)
        if hash_value:
            summary[name] = {"status":"ok","hash":hash_value}
        else:
            summary[name] = {"status":"missing"}
            if ref_candidate:
                shutil.copy2(ref_candidate,path)
                log(f"♻️ Fichier {name} restauré depuis {ref_candidate}")
            else:
                log(f"⚠️ Impossible de restaurer {name} : copie introuvable")

    with open(LOG_PATH.replace(".log","_summary.json"),"w",encoding="utf-8") as f:
        json.dump(summary,f,indent=2)
    log("✅ Vérification terminée – résumé enregistré.")

if __name__ == "__main__":
    log("=== Cycle AutoRepair lancé ===")
    verify_and_repair()
