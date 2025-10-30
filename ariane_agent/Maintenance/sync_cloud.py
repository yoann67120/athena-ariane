import os, time, json, datetime, requests

LOG = r"C:\Ariane-Agent\logs\AutoMaintenance.log"
# 🔁 On passe sur le canal de synchro ouvert (aucune vérif HMAC)
CLOUD_URL = "https://ariane.ngrok.io/bridge/sync"

def log(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.datetime.now()}] [sync_cloud] {msg}\n")

def main():
    log("=== DÉMARRAGE SYNC_CLOUD (canal ouvert /bridge/sync) ===")
    while True:
        try:
            with open(LOG, "r", encoding="utf-8") as f:
                logs = f.read()[-5000:]
            payload = {"logs": logs, "timestamp": int(time.time())}
            r = requests.post(CLOUD_URL, json=payload, timeout=10)
            log(f"☁️ Sync envoyée (statut={r.status_code})")
        except Exception as e:
            log(f"❌ Erreur sync : {e}")
        time.sleep(300)

if __name__ == "__main__":
    main()
