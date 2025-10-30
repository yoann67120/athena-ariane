# ====================================================================
# 🌐 Auto-Harmony / Sync-GPT – Phase 14.3
# ====================================================================

import os, time, json, requests, datetime, hashlib

CONFIG_PATH = r"C:\\Ariane-Agent\\AutoPilot\\syncgpt_config.json"
LOG_PATH = r"C:\\Ariane-Agent\\logs\\syncgpt.log"
STATE_PATH = r"C:\\Ariane-Agent\\logs\\syncgpt_state.json"

def log(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    with open(LOG_PATH,"a",encoding="utf-8") as f: f.write(line+"\\n")

def sha256sum(path):
    h = hashlib.sha256()
    with open(path,"rb") as f:
        for chunk in iter(lambda: f.read(4096), b""): h.update(chunk)
    return h.hexdigest()

def get_local_status(url):
    try:
        r = requests.get(url, timeout=5)
        return r.json()
    except Exception as e:
        return {"error": str(e)}

def send_to_remote(url, payload):
    try:
        r = requests.post(url, json=payload, timeout=10)
        return r.status_code, r.text
    except Exception as e:
        return 500, str(e)

def sync_loop():
    if not os.path.exists(CONFIG_PATH):
        log("⚠️ Fichier de config SyncGPT introuvable.")
        return
    config = json.load(open(CONFIG_PATH, encoding="utf-8"))
    if not config.get("enabled", True):
        log("⏸️ SyncGPT désactivé.")
        return
    local_url = config["local_status_url"]
    remote_url = config["remote_sync_url"]
    interval = config.get("interval_minutes",10)*60
    log(f"=== Démarrage Auto-Harmony (toutes {interval/60:.0f} min) ===")

    while True:
        status = get_local_status(local_url)
        payload = {
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "status": status,
            "hashes": {
                "Invoke-AgentSecure.py": sha256sum(r"C:\\Ariane-Agent\\Scripts\\Invoke-AgentSecure.py"),
                "autopilot_server.py": sha256sum(r"C:\\Ariane-Agent\\AutoPilot\\autopilot_server.py")
            }
        }
        code,resp = send_to_remote(remote_url, payload)
        log(f"📡 Sync envoyé → {code} {resp[:100]}")
        with open(STATE_PATH,"w",encoding="utf-8") as f: json.dump(payload,f,indent=2)
        time.sleep(interval)

if __name__ == "__main__":
    sync_loop()
