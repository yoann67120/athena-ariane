# ====================================================================
# 🧩 ARIANE V4 - MODULE AUTO_SYNC (Phase 23)
# Synchronise les répertoires locaux vers AgentKit Cloud (Mirror)
# ====================================================================

import os, json, hashlib, requests, hmac
from datetime import datetime

BASE_DIR   = r"C:\Ariane-Agent"
MODULES    = os.path.join(BASE_DIR,"Modules")
SCRIPTS    = os.path.join(BASE_DIR,"Scripts")
BACKUPS    = os.path.join(BASE_DIR,"Backups")
CONFIG     = os.path.join(BASE_DIR,"config")
LOGS       = os.path.join(BASE_DIR,"logs")
SECRET     = os.path.join(BASE_DIR,"secrets","bridge_hmac.key")
MANIFEST   = os.path.join(LOGS,"SyncManifest.json")
LOG_PATH   = os.path.join(LOGS,"AutoSync.log")
CLOUD_URL  = "https://ariane.ngrok.io/bridge/mirror"

SYNC_PATHS = [MODULES,SCRIPTS,BACKUPS,CONFIG]

def log(msg):
    os.makedirs(LOGS, exist_ok=True)
    with open(LOG_PATH,"a",encoding="utf-8") as f:
        f.write(f"[{datetime.now()}] {msg}\n")

def hash_file(path):
    h = hashlib.sha256()
    try:
        with open(path,"rb") as f:
            for chunk in iter(lambda:f.read(4096),b""):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return None

def collect_manifest():
    manifest = {}
    for root_dir in SYNC_PATHS:
        if not os.path.exists(root_dir):
            continue
        for root, _, files in os.walk(root_dir):
            for file in files:
                full = os.path.join(root, file)
                rel  = os.path.relpath(full, BASE_DIR)
                try:
                    manifest[rel] = {
                        "hash": hash_file(full),
                        "size": os.path.getsize(full),
                        "mtime": os.path.getmtime(full)
                    }
                except Exception:
                    pass
    with open(MANIFEST,"w",encoding="utf-8") as f:
        json.dump(manifest,f,indent=2)
    log(f"🧩 Manifeste généré : {len(manifest)} fichiers.")
    return manifest

def sign_payload(payload):
    try:
        with open(SECRET,"rb") as f:
            key=f.read().strip()
        data=json.dumps(payload,separators=(",",":")).encode("utf-8")
        return hmac.new(key,data,hashlib.sha256).hexdigest()
    except Exception:
        return ""

def send_sync(data):
    try:
        sig=sign_payload(data)
        headers={"Content-Type":"application/json"}
        if sig: headers["X-HMAC-Signature"]=sig
        r=requests.post(CLOUD_URL,data=json.dumps(data),headers=headers,timeout=15)
        log(f"☁️ Sync envoyée : {r.status_code}")
    except Exception as e:
        log(f"⚠️ Erreur sync cloud: {e}")

if __name__=="__main__":
    log("=== DÉMARRAGE AUTO_SYNC ===")
    manifest = collect_manifest()
    payload = {
        "timestamp": datetime.now().isoformat(),
        "agent": "ArianeV4",
        "files_count": len(manifest),
        "manifest": manifest
    }
    send_sync(payload)
    log("=== FIN AUTO_SYNC ===")
