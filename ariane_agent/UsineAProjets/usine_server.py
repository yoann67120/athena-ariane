# ====================================================================
# 🚀 ARIANE V4 - USINE À PROJETS (v1.2)
# Auteur : Yoann Rousselle
# Description : Orchestrateur central (Flask) utilisant AgentKit
# Objectif : Créer, lister et déployer automatiquement des projets
# ====================================================================

import os
import sys
import json
import datetime
from flask import Flask, request, jsonify

# --- Ajout du chemin AgentKit ---
AGENTKIT_PATH = r"C:\Ariane-Agent"
if AGENTKIT_PATH not in sys.path:
    sys.path.append(AGENTKIT_PATH)

try:
    import agentkit
except ImportError:
    raise RuntimeError("❌ AgentKit introuvable. Vérifie que le dossier C:\\Ariane-Agent\\agentkit existe bien.")

# ============================================================
# CONFIGURATION DE BASE
# ============================================================
BASE_DIR = r"C:\Ariane-Agent\UsineAProjets"
LOGS_DIR = os.path.join(BASE_DIR, "logs")
LOG_FILE = os.path.join(LOGS_DIR, "usine_server.log")

os.makedirs(LOGS_DIR, exist_ok=True)
app = Flask(__name__)

# ============================================================
# UTILITAIRES
# ============================================================

def log(message: str):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    msg = f"[{ts}] {message}"
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(msg + "\n")
    print(msg)

# ============================================================
# JOURNALISATION PHASE 3.5 – Usine à Projets
# ============================================================
def log_phase3(event: str, details: str):
    """Écrit un événement détaillé dans C:\\Ariane-Agent\\logs\\Phase3.log"""
    path = r"C:\\Ariane-Agent\\logs\\Phase3.log"
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {event} – {details}\n"
    with open(path, "a", encoding="utf-8") as f:
        f.write(line)

# ============================================================
# ENDPOINTS PRINCIPAUX
# ============================================================

@app.route("/")
def index():
    return jsonify({
        "status": "✅ Usine à Projets opérationnelle (AgentKit relié)",
        "endpoints": ["/create", "/list", "/deploy"]
    })

@app.route("/create", methods=["POST"])
def create_project():
    data = request.get_json(force=True)
    name = data.get("name")
    type_ = data.get("type", "Web")
    if not name:
        return jsonify({"error": "Paramètre 'name' obligatoire"}), 400

    try:
        # On envoie un dict complet à AgentKit
        payload = {"name": name, "type": type_}
        result = agentkit.run_action("create_project", params=payload)
        log(f"🧩 Création via AgentKit : {name}")
        log_phase3("CREATE", f"{name} – succès")
        return jsonify(result)
    except Exception as e:
        log(f"❌ Erreur création : {e}")
        log_phase3("ERROR", f"{name} – {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/list", methods=["GET"])
def list_projects():
    try:
        result = agentkit.run_action("list_projects")
        return jsonify({"projects": result})
    except Exception as e:
        log(f"❌ Erreur liste : {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/deploy", methods=["POST"])
def deploy_project():
    data = request.json or {}
    name = data.get("name")
    if not name:
        return jsonify({"error": "Paramètre 'name' obligatoire"}), 400
    try:
        result = agentkit.run_action("deploy_project", name=name)
        log(f"🚀 Déploiement via AgentKit : {name}")
        log_phase3("DEPLOY", f"{name} – succès")
        return jsonify({"message": result})
    except Exception as e:
        log(f"❌ Erreur déploiement : {e}")
        return jsonify({"error": str(e)}), 500

# ====================================================================
# 🔗 Intégration du pont réseau GPT-5 ↔ Usine (Phase 4.1)
# ====================================================================
from bridge_handler import bridge_bp
app.register_blueprint(bridge_bp)

# ============================================================
# LANCEMENT DU SERVEUR
# ============================================================
if __name__ == "__main__":
    log("=== Démarrage de l’Usine à Projets (AgentKit relié) ===")
    app.run(host="0.0.0.0", port=5050, debug=True)
