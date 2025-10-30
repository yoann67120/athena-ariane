# ====================================================================
# 🤖 AutoPilot Supervisor – Version finale (Phase 14.1 + PATCH)
# Surveille Bridge / Usine / AutoPilot et expose /status sur port 5081
# ====================================================================

import os, time, datetime, subprocess, psutil, threading
from flask import Flask, jsonify

app = Flask(__name__)

LOG_PATH = r"C:\\Ariane-Agent\\logs\\supervisor.log"
SERVICES = {
    "Bridge": {"port": 5075, "process": "bridge"},
    "Usine": {"port": 5050, "process": "usine"},
    "AutoPilot": {"port": 5080, "process": "autopilot"}
}

def log(msg):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(line + "\\n")

def is_port_alive(port):
    for c in psutil.net_connections(kind="inet"):
        if c.laddr.port == port and c.status == psutil.CONN_LISTEN:
            return True
    return False

def restart_service(name, port):
    log(f"⚠️ {name} inactif sur port {port} → tentative de relance…")
    ps1 = os.path.join(r"C:\\Ariane-Agent", "Start-AgentSystem.ps1")
    try:
        subprocess.Popen(["powershell","-ExecutionPolicy","Bypass","-File",ps1])
        log(f"✅ {name} relancé via Start-AgentSystem.ps1")
    except Exception as e:
        log(f"❌ Erreur redémarrage {name}: {e}")

def check_all():
    status = {}
    for name, info in SERVICES.items():
        alive = is_port_alive(info["port"])
        status[name] = "🟢" if alive else "🔴"
        if not alive:
            restart_service(name, info["port"])
    return status

@app.route("/status")
def status_http():
    s = check_all()
    return jsonify({
        "timestamp": datetime.datetime.now().isoformat(),
        "services": s
    })

if __name__ == "__main__":
    log("=== Démarrage AutoPilot Supervisor (port 5081) ===")
    # Thread de surveillance permanente
    def background():
        while True:
            check_all()
            time.sleep(60)
    threading.Thread(target=background, daemon=True).start()
    app.run(host="0.0.0.0", port=5081)
