# ====================================================================
# 🚀 COCKPIT USINE À PROJETS – SERVER FINAL
# ====================================================================
from flask import Flask, render_template, jsonify, request
import requests, os, datetime, json, shutil

# --- CONFIGURATION ---
USINE_URL = "http://localhost:5050"
LOG_DIR = r"C:\Ariane-Agent\logs"
LOG_FILE = os.path.join(LOG_DIR, "CockpitUsine.log")
PROJECTS_DIR = r"C:\Ariane-Agent\Projets"
USINE_LOG = os.path.join(LOG_DIR, "UsineServer.log")

os.makedirs(LOG_DIR, exist_ok=True)
os.makedirs(PROJECTS_DIR, exist_ok=True)

app = Flask(__name__, template_folder="templates", static_folder="static")

# --- UTILITAIRES ---
def log(msg):
    ts = datetime.datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")
    line = f"{ts} {msg}"
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")
    print(line)

def fetch_projects():
    try:
        resp = requests.get(f"{USINE_URL}/list", timeout=5)
        data = resp.json()
        return data.get("result", [])
    except Exception as e:
        log(f"❌ Erreur récupération projets : {e}")
        return []

def relay_post(endpoint, payload):
    try:
        r = requests.post(f"{USINE_URL}/{endpoint}", json=payload, timeout=10)
        return r.json()
    except Exception as e:
        log(f"❌ Erreur POST {endpoint} : {e}")
        return {"error": str(e)}

# --- ROUTES ---
@app.route("/")
def home():
    log("🧭 Accès au Cockpit Usine")
    return render_template("index.html")

@app.route("/projects")
def projects():
    return jsonify(fetch_projects())

@app.route("/create", methods=["POST"])
def create():
    data = request.get_json(force=True)
    log(f"🆕 Création projet : {data}")
    res = relay_post("create", data)
    return jsonify(res)

@app.route("/deploy", methods=["POST"])
def deploy():
    data = request.get_json(force=True)
    log(f"🚀 Déploiement : {data}")
    res = relay_post("deploy", data)
    return jsonify(res)

@app.route("/delete", methods=["POST"])
def delete_project():
    data = request.get_json(force=True)
    name = data.get("name")
    if not name:
        return jsonify({"error": "Nom manquant"})
    try:
        target = os.path.join(PROJECTS_DIR, name.strip())
        if os.path.exists(target):
            shutil.rmtree(target)
            log(f"🗑️ Projet supprimé : {name}")
            return jsonify({"status": "ok", "message": f"Projet {name} supprimé."})
        return jsonify({"error": "Projet introuvable."})
    except Exception as e:
        log(f"❌ Erreur suppression projet : {e}")
        return jsonify({"error": str(e)})

@app.route("/logs")
def get_logs():
    try:
        if os.path.exists(USINE_LOG):
            with open(USINE_LOG, "r", encoding="utf-8") as f:
                lines = f.readlines()[-40:]
            return jsonify({"lines": lines})
        return jsonify({"lines": ["Aucun log trouvé."]})
    except Exception as e:
        return jsonify({"lines": [f"Erreur lecture logs : {e}"]})

@app.route("/open-athena")
def open_athena():
    log("🧠 Ouverture du Cockpit Athena")
    os.system("start http://localhost:8080")
    return jsonify({"status": "ok", "message": "Cockpit Athena ouvert."})

# --- LANCEMENT ---
if __name__ == "__main__":
    log("=== Démarrage Cockpit Usine à Projets – Version finale ===")
    app.run(host="0.0.0.0", port=5051, debug=True)
