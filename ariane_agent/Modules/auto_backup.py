# ====================================================================
# 🧩 ARIANE V4 – MODULE AUTO_BACKUP (Phase 24)
# Crée un snapshot complet versionné + envoi Cloud
# ====================================================================

import os, json, hashlib, hmac, zipfile, requests
from datetime import datetime

BASE = r"C:\Ariane-Agent"
SNAP_DIR = os.path.join(BASE,"Backups","ArianeV4_Snapshots")
LOG_PATH = os.path.join(BASE,"logs","AutoBackup.log")
SECRET_PATH = os.path.join(BASE,"secrets","bridge_hmac.key")
CLOUD_URL = "https://ariane.ngrok.io/bridge/mirror"

INCLUDE_DIRS = [
    os.path.join(BASE,"Modules"),
    os.path.join(BASE,"Scripts"),
    os.path.join(BASE,"config"),
    os.path.join(BASE,"logs"),
    os.path.join(BASE,"Backups")
]

def log(msg):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    with open(LOG_PATH,"a",encoding="utf-8") as f:
        f.write(f"[{datetime.now()}] {msg}\n")

def create_snapshot():
    os.makedirs(SNAP_DIR, exist_ok=True)
    name = f"ArianeV4_Snapshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}.zip"
    path = os.path.join(SNAP_DIR, name)
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zf:
        for folder in INCLUDE_DIRS:
            if not os.path.exists(folder):
                continue
            for root,_,files in os.walk(folder):
                for file in files:
                    full = os.path.join(root,file)
                    rel = os.path.relpath(full, BASE)
                    try:
                        zf.write(full, rel)
                    except Exception:
                        pass
    return path

def sign_file(path):
    try:
        with open(path,"rb") as f: data=f.read()
        sha = hashlib.sha256(data).hexdigest()
        key = open(SECRET_PATH,"rb").read().strip()
        hmac_sig = hmac.new(key,data,hashlib.sha256).hexdigest()
        return {"sha256":sha,"hmac":hmac_sig}
    except Exception as e:
        log(f"[ERREUR] Signature: {e}")
        return {}

def rotate_backups():
    files = sorted([f for f in os.listdir(SNAP_DIR) if f.endswith(".zip")],
                   key=lambda x: os.path.getmtime(os.path.join(SNAP_DIR,x)))
    while len(files) > 5:
        old = files.pop(0)
        try:
            os.remove(os.path.join(SNAP_DIR,old))
            log(f"🗑️ Suppression ancienne sauvegarde : {old}")
        except Exception as e:
            log(f"[ERREUR] Suppression {old}: {e}")

def send_report(meta):
    try:
        headers={"Content-Type":"application/json"}
        r=requests.post(CLOUD_URL,data=json.dumps(meta),headers=headers,timeout=15)
        log(f"☁️ Rapport envoyé : {r.status_code}")
    except Exception as e:
        log(f"⚠️ Erreur envoi cloud: {e}")

if __name__=="__main__":
    log("=== DÉMARRAGE AUTO_BACKUP ===")
    rotate_backups()
    snap = create_snapshot()
    sig = sign_file(snap)
    meta = {
        "timestamp": datetime.now().isoformat(),
        "snapshot": os.path.basename(snap),
        "path": snap,
        "size": os.path.getsize(snap),
        "signature": sig
    }
    log(f"💾 Snapshot créé : {snap} ({meta['size']} octets)")
    send_report(meta)
    log("=== FIN AUTO_BACKUP ===")
