# ====================================================================
# 🧩 ARIANE V4 - MODULE STATUS_CLOUD (Phase 19)
# ====================================================================
import os, json, time, socket, hmac, hashlib, subprocess
from datetime import datetime

LOG_PATH    = r"C:\Ariane-Agent\logs\AutoHarmony.log"
SECRET_PATH = r"C:\Ariane-Agent\secrets\bridge_hmac.key"
CLOUD_URL   = "https://ariane.ngrok.io/bridge/sync"

def log(msg: str):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.now()}] {msg}\n")

def ensure_imports():
    import importlib
    for m in ("psutil","requests"):
        try:
            importlib.import_module(m)
        except Exception as e:
            log(f"[ERREUR] Module Python manquant: {m} – {e}")
            raise

def collect_status():
    import psutil, requests
    cpu = psutil.cpu_percent(interval=1)
    ram = psutil.virtual_memory().percent
    uptime = int(time.time() - psutil.boot_time())
    hostname = socket.gethostname()
    ping_ok = (os.system("ping -n 1 8.8.8.8 >nul 2>&1") == 0)

    bridge_ok = usine_ok = False
    try:
        r1 = requests.get("http://127.0.0.1:5075/status", timeout=2)
        bridge_ok = r1.status_code == 200
    except Exception: pass
    try:
        r2 = requests.get("http://127.0.0.1:5050/", timeout=2)
        usine_ok = r2.status_code == 200
    except Exception: pass

    return {
        "timestamp": datetime.now().isoformat(),
        "host": hostname,
        "cpu": cpu,
        "ram": ram,
        "uptime_sec": uptime,
        "ping": ping_ok,
        "bridge_local_ok": bridge_ok,
        "usine_local_ok": usine_ok,
        "process_count": len(psutil.pids())
    }

def sign_payload(payload: dict) -> str:
    try:
        with open(SECRET_PATH, "rb") as f:
            key = f.read().strip()
    except Exception:
        return ""
    data = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    return hmac.new(key, data, hashlib.sha256).hexdigest()

def send_status():
    import requests
    data = collect_status()
    sig = sign_payload(data)
    headers = {"Content-Type": "application/json"}
    if sig:
        headers["X-HMAC-Signature"] = sig
    try:
        r = requests.post(CLOUD_URL, data=json.dumps(data), headers=headers, timeout=10)
        log(f"☁️ Statut envoyé : {r.status_code}")
    except Exception as e:
        log(f"⚠️ Erreur d'envoi : {e}")

if __name__ == "__main__":
    try:
        log("=== DÉMARRAGE STATUS_CLOUD ===")
        ensure_imports()
        send_status()
        log("=== FIN STATUS_CLOUD ===")
    except Exception as e:
        log(f"[FATAL] {e}")
