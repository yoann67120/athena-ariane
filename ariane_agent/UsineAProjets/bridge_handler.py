# ====================================================================
# 🚀 ARIANE V4 - USINE À PROJETS (Phase 4.2)
# Fichier : bridge_handler.py
# Auteur : Yoann Rousselle
# Description : Pont sécurisé GPT-5 ↔ Usine (Flask + AgentKit)
# ====================================================================

import os
import datetime
import json
import hmac
import hashlib
from flask import Blueprint, request, jsonify
import agentkit

bridge_bp = Blueprint("bridge", __name__)
LOG_FILE = r"C:\Ariane-Agent\logs\bridge.log"

# 🔐 Clé secrète partagée entre GPT-5 et l’Usine
SECRET_KEY = os.getenv("USINE_SECRET_KEY", "ARIANE_SECRET_2025").encode("utf-8")

def log_event(message: str):
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{ts}] {message}\n")

def build_response(status, action=None, result=None, error=None):
    return {
        "protocol": "UsineProtocol_v1",
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "status": status,
        "action": action,
        "result": result,
        "error": error,
    }

@bridge_bp.route("/bridge", methods=["POST"])
def bridge():
    try:
        raw_body = request.data
        signature = request.headers.get("X-Signature", "")

        # ✅ Vérification de signature HMAC-SHA256
        expected_signature = hmac.new(SECRET_KEY, raw_body, hashlib.sha256).hexdigest()
        if not hmac.compare_digest(signature, expected_signature):
            log_event("❌ Signature invalide reçue.")
            return jsonify(build_response("error", "auth", error="Invalid signature")), 403

        data = request.get_json(force=True)
        token = data.get("token", "")
        action = data.get("action")
        params = data.get("params", {})

        LOCAL_KEY = os.getenv("ARIANE_LOCAL_KEY", "ARIANE_LOCAL_KEY")
        if token != LOCAL_KEY:
            log_event("❌ Jeton local invalide.")
            return jsonify(build_response("error", "auth", error="Invalid token")), 403

        log_event(f"🔗 Requête authentifiée : action={action} params={params}")
        result = agentkit.run_action(action, **params)
        log_event(f"✅ Action '{action}' exécutée avec succès.")

        return jsonify(build_response("success", action, result=result))

    except Exception as e:
        log_event(f"⚠️ Erreur : {str(e)}")
        return jsonify(build_response("error", "internal", error=str(e))), 500
