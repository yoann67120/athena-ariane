# ====================================================================
# 🧩 ARIANE V4 - MODULE AUTO_REPAIR (Phase 22)
# Vérifie intégrité des modules, restaure si besoin, et envoie un rapport Cloud
# ====================================================================

import os, json, hashlib, shutil, psutil, subprocess, requests, hmac
from datetime import datetime

BASE_DIR   = r"C:\Ariane-Agent"
MODULES    = os.path.join(BASE_DIR,"Modules")
LOGS       = os.path.join(BASE_DIR,"logs")
BACKUPS    = os.path.join(BASE_DIR,"Backups")
SECRET     = os.path.join(BASE_DIR,"secrets","bridge_hmac.key")
CLOUD_URL  = "https://ariane.ngrok.io/bridge/sync"
LOG_PATH   = os.path.join(LOGS,"AutoRepair.log")

CRITICAL   = ["status_cloud.py","learning_engine.py","auto_adapt.py"]

def log(msg):
    os.makedirs(LOGS, exist_ok=True)
    with open(LOG_PATH,"a",encoding="utf-8") as f:
        f.write(f"[{datetime.now()}] {msg}\n")

def file_hash(path):
    h = hashlib.sha256()
    with open(path,"rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            h.update(chunk)
    return h.hexdigest()

def sign_payload(payload):
    try:
        with open(SECRET,"rb") as f:
            key=f.read().strip()
        data=json.dumps(payload,separators=(",",":")).encode("utf-8")
        return hmac.new(key,data,hashlib.sha256).hexdigest()
    except Exception:
        return ""

def send_report(data):
    try:
        sig=sign_payload(data)
        headers={"Content-Type":"application/json"}
        if sig: headers["X-HMAC-Signature"]=sig
        r=requests.post(CLOUD_URL,data=json.dumps(data),headers=headers,timeout=10)
        log(f"☁️ Rapport envoyé : {r.status_code}")
    except Exception as e:
        log(f"⚠️ Erreur envoi cloud: {e}")

def verify_and_repair():
    repaired=[]
    for name in CRITICAL:
        main=os.path.join(MODULES,name)
        backup=os.path.join(BACKUPS,name)
        if not os.path.exists(main):
            log(f"[ALERTE] Module manquant : {name} → restauration...")
            if os.path.exists(backup):
                shutil.copy2(backup, main)
                repaired.append(name)
                continue
        try:
            if file_hash(main)!=file_hash(backup):
                log(f"[ALERTE] Fichier altéré : {name} → restauration...")
                shutil.copy2(backup, main)
                repaired.append(name)
        except Exception as e:
            log(f"[ERREUR] Vérif {name}: {e}")
    return repaired

def restart_services():
    try:
        subprocess.Popen(["powershell","-ExecutionPolicy","Bypass","-File",
                          os.path.join(BASE_DIR,"Start-AgentSystem.ps1")])
        log("🔁 Redémarrage des services Ariane lancé.")
    except Exception as e:
        log(f"[ERREUR] Redémarrage : {e}")

if __name__=="__main__":
    log("=== DÉMARRAGE AUTO_REPAIR ===")
    repaired = verify_and_repair()
    if repaired:
        log(f"🧩 Modules réparés : {repaired}")
        restart_services()
    else:
        log("✅ Aucun module à réparer.")
    payload={
        "timestamp": datetime.now().isoformat(),
        "repaired": repaired,
        "system_status": "OK" if not repaired else "REPAIRED"
    }
    send_report(payload)
    log("=== FIN AUTO_REPAIR ===")
