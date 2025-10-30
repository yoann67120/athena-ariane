# ====================================================================
# 🤖 AutoPilot Server – Phase 14
# Objectif : Pilotage automatique via GPT-5 ↔ Bridge (HMAC sécurisé)
# ====================================================================

import os, json, datetime, subprocess, hmac, hashlib
from flask import Flask, request, jsonify

app = Flask(__name__)

LOG_PATH = r"C:\\Ariane-Agent\\logs\\autopilot.log"
SECRET_PATH = r"C:\\Ariane-Agent\\secrets\\bridge_hmac.key"
ACTIONS_DIR = r"C:\\Ariane-Agent\\agentkit\\actions"

def log(msg):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(f"[{ts}] {msg}\\n")
    print(msg)

def verify_hmac(payload, signature):
    key = open(SECRET_PATH, "rb").read().strip()
    data = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    expected = hmac.new(key, data, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)

@app.route("/secure_execute", methods=["POST"])
def secure_execute():
    payload = request.get_json(force=True)
    signature = request.headers.get("X-HMAC-Signature", "")
    if not verify_hmac(payload, signature):
        log("❌ Signature HMAC invalide")
        return jsonify({"error": "invalid_signature"}), 401

    action = payload.get("action")
    params = payload.get("params", {})
    log(f"🧭 Ordre reçu : {action}")

    path = os.path.join(ACTIONS_DIR, f"{action}.py")
    if not os.path.exists(path):
        log(f"⚠️ Action inconnue : {action}")
        return jsonify({"error": "unknown_action"}), 404

    try:
        result = subprocess.run(["python", path], capture_output=True, text=True, timeout=120)
        log(f"✅ Action exécutée : {action}")
        return jsonify({"status": "ok", "output": result.stdout.strip()})
    except Exception as e:
        log(f"❌ Erreur exécution {action}: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "🟢 AutoPilot en ligne",
        "endpoints": ["/secure_execute"],
        "timestamp": datetime.datetime.now().isoformat()
    })

if __name__ == "__main__":
    log("=== Démarrage AutoPilot (Phase 14) ===")
    app.run(host="0.0.0.0", port=5080)
