import os, requests, time, datetime, json

BRIDGE_URL = "https://ariane.ngrok.io/bridge"
LOG = r"C:\Ariane-Agent\logs\AutoMaintenance.log"

def log(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.datetime.now()}] [auto_deploy] {msg}\n")

def main():
    log("=== DÉMARRAGE AUTO_DEPLOY ===")
    while True:
        try:
            r = requests.post(BRIDGE_URL, json={"action": "list_projects"})
            data = r.json()
            for p in data.get("result", []):
                path = p.get("path")
                if path and not os.path.exists(path):
                    log(f"🧩 Nouveau projet détecté : {p.get('name')}")
                    os.system(f"curl -X POST {BRIDGE_URL} -H \"Content-Type: application/json\" -d '{{\"action\":\"deploy_project\",\"name\":\"{p.get('name')}\"}}'")
        except Exception as e:
            log(f"❌ Erreur deploy : {e}")
        time.sleep(300)  # Toutes les 5 minutes

if __name__ == "__main__":
    main()
