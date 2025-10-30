# ====================================================================
# 🤖 Ariane Agent Bridge - Stable Server v2
# Port : 5000
# Description : Pont entre GPT-5 et l’environnement local Athena
# ====================================================================

import os
import datetime
import subprocess
from flask import Flask, request, jsonify

app = Flask(__name__)
LOG_FILE = r"C:\Ariane-Agent\logs\Agent.log"

def log(msg: str):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{ts}] {msg}\n")
    print(msg)

@app.route("/execute", methods=["POST"])
def execute():
    data = request.get_json(force=True)
    action = data.get("action", "")
    param = data.get("param", "")
    source = data.get("source", "Unknown")
    log(f"🧠 Requête reçue de {source} : {action} ({param})")

    try:
        if action.lower() == "exec":
            result = subprocess.run(
                ["powershell", "-Command", param],
                capture_output=True, text=True, timeout=15
            )
            output = result.stdout.strip() or result.stderr.strip()
            log(f"✅ Exécution PowerShell OK : {output}")
            return jsonify({"status": "ok", "output": output})
        else:
            log(f"⚠️ Action inconnue : {action}")
            return jsonify({"status": "error", "error": "Action inconnue"})
    except Exception as e:
        log(f"❌ Erreur exécution : {e}")
        return jsonify({"status": "error", "error": str(e)})

@app.route("/", methods=["GET"])
def root():
    return jsonify({"status": "ok", "service": "Ariane Agent Bridge", "port": 5000})

if __name__ == "__main__":
    log("=== Démarrage Ariane Agent Bridge (port 5000) ===")
    app.run(host="0.0.0.0", port=5000)
