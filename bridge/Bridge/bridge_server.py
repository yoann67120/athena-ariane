# -*- coding: utf-8 -*-
"""
bridge_server.py – v15.3 Cloud Ready (FINAL)
Bridge sécurisé reliant AgentKit Cloud ↔ Usine locale + AutoHarmony Sync
Routes:
  - GET  /status
  - POST /bridge
  - POST /bridge/sync
  - POST /bridge/register
  - POST /bridge/handshake
  - POST /register_bridge
"""

import os, json, time, datetime, hmac, hashlib
from flask import Flask, request, jsonify

# Dépendances internes
from selfguard import SelfGuard
from agentkit_router import AgentKitRouter

app = Flask(__name__)
sg = SelfGuard()
router = AgentKitRouter()

# === Chemins système ===
LOG_RUNTIME = r"C:\Ariane-Agent\logs\BridgeRuntime.log"
SYNC_LOG    = r"C:\Ariane-Agent\logs\sync_inbound.log"
SECRET_PATH = r"C:\Ariane-Agent\secrets\bridge_hmac.key"
DATA_DIR    = r"C:\Ariane-Agent\data"
REGISTRY_FILE = os.path.join(DATA_DIR, "bridge_registry.json")

os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(os.path.dirname(LOG_RUNTIME), exist_ok=True)

# ===============================================================
# ✅ STATUS
# ===============================================================
@app.route('/status', methods=['GET'])
@app.route('/bridge/status', methods=['GET'])
def status():
    try:
        status = {
            "Bridge": "🟢 Actif",
            "HMAC": "✅ OK" if os.path.exists(SECRET_PATH) else "⚠️ Absent",
            "Logs": True,
            "Port": int(os.environ.get('BRIDGE_PORT', '5075')),
            "SelfGuard": "✅ Chargé",
            "TimestampTolerance": "±300s"
        }
        return jsonify(status)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ===============================================================
# 🔐 BRIDGE PRINCIPAL (Cloud → actions)
# ===============================================================
@app.route('/bridge', methods=['POST'])
@app.route('/agentkit/command', methods=['POST'])
def bridge():
    """Réception d’un ordre signé provenant du Cloud GPT/AgentKit"""
    try:
        t0 = time.time()
        data = request.get_json(silent=True) or {}
        action = data.get('action')
        payload = data.get('payload', {})

        # --- En-têtes HMAC ---
        signature = request.headers.get('X-HMAC', '')
        nonce = request.headers.get('X-Nonce', '')
        ts = int(request.headers.get('X-Timestamp', '0'))

        # --- Vérification via SelfGuard ---
        ok, reason = sg.verify(action or '', payload, nonce, ts, signature)
        print(f"[Bridge] 🔐 Vérif HMAC → {reason}")

        if not ok:
            sg.audit({
                "time": int(time.time()),
                "endpoint": "/bridge",
                "action": action,
                "nonce": nonce,
                "timestamp": ts,
                "verify": reason,
                "result": "rejected"
            })
            return jsonify({"error": reason}), 401

        # --- Exécution de l’action ---
        result = router.handle(action, payload)
        latency = int((time.time() - t0) * 1000)

        sg.audit({
            "time": int(time.time()),
            "endpoint": "/bridge",
            "action": action,
            "nonce": nonce,
            "timestamp": ts,
            "verify": reason,
            "latency_ms": latency,
            "result": result.get('status', 'unknown')
        })

        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ===============================================================
# 🌐 SYNC ENDPOINT – AutoPilot / AutoHarmony
# ===============================================================
def verify_hmac_optional(payload, signature):
    if not signature:
        return True  # Pas de signature → on accepte (local/testing)
    try:
        key = open(SECRET_PATH, "rb").read().strip()
        data = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        expected = hmac.new(key, data, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature)
    except Exception:
        return False


@app.route("/bridge/sync", methods=["POST"])
def bridge_sync():
    try:
        payload = request.get_json(force=True)
        signature = request.headers.get("X-HMAC-Signature", "")
        if not verify_hmac_optional(payload, signature):
            return jsonify({"error": "invalid_signature"}), 401

        ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(SYNC_LOG, "a", encoding="utf-8") as f:
            f.write(f"[{ts}] SYNC_RECEIVED: {json.dumps(payload)}\n")

        return jsonify({"status": "received", "timestamp": ts})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ===============================================================
# 🧩 REGISTER ENDPOINT – Enregistrement du Bridge public (Cloud → Local)
# ===============================================================
@app.route("/bridge/register", methods=["POST"])
def register_bridge():
    try:
        data = request.get_json(silent=True) or {}
        bridge_url = data.get("bridge_url")
        timestamp = data.get("timestamp")
        hmac_key = data.get("hmac_key")
        system = data.get("system", "ArianeV4")

        if not data:
            return jsonify({"status": "error", "reason": "empty_request"}), 400

        if not bridge_url or not hmac_key:
            return jsonify({"status": "error", "reason": "missing_fields"}), 400

        record = {
            "bridge_url": bridge_url,
            "timestamp": timestamp or datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "system": system,
            "hmac_key": hmac_key
        }

        with open(REGISTRY_FILE, "w", encoding="utf-8") as f:
            json.dump(record, f, indent=4)

        with open(LOG_RUNTIME, "a", encoding="utf-8") as logf:
            logf.write(f"[REGISTER] {bridge_url} enregistré.\n")

        print(f"[REGISTER] Bridge public enregistré : {bridge_url}")
        return jsonify({"status": "ok", "message": "Bridge enregistré avec succès."})
    except Exception as e:
        return jsonify({"status": "error", "reason": str(e)}), 500


# ===============================================================
# 🤝 HANDSHAKE ENDPOINT – Validation HMAC Cloud ↔ Local
# ===============================================================
@app.route("/bridge/handshake", methods=["POST"])
def handshake():
    try:
        key = open(SECRET_PATH, "rb").read().strip()
        payload = {"timestamp": int(time.time())}
        digest = hmac.new(key, json.dumps(payload).encode(), hashlib.sha256).hexdigest()
        return jsonify({
            "status": "verified",
            "digest": digest,
            "system": "ArianeV4",
            "timestamp": payload["timestamp"]
        })
    except Exception as e:
        return jsonify({"status": "error", "reason": str(e)}), 500


# ======================================================
# 🧩 Endpoint /register_bridge – Enregistrement Cloud
# ======================================================
@app.route('/register_bridge', methods=['POST'])
def register_bridge_cloud():
    try:
        data = request.get_json(force=True)
        log_path = r"C:\Ariane-Agent\logs\AgentCloud.log"
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"[{ts}] 🔗 Enregistrement reçu depuis AgentKit Cloud : {json.dumps(data, ensure_ascii=False)}\n")

        response = {
            "status": "ok",
            "bridge": "ArianeV4",
            "registered_at": ts,
            "url": data.get("url"),
            "protocol": data.get("protocol"),
            "version": data.get("version")
        }
        return jsonify(response), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# ====================================================================
# 🧩 ENDPOINT : /bridge/mirror  (Phase 23 - Version stable)
# Réception et journalisation des synchronisations Auto-Sync
# ====================================================================
@app.route('/bridge/mirror', methods=['POST'])
def mirror_bridge():
    try:
        # --- Lecture brute pour éviter perte de contenu ---
        raw_data = request.data.decode("utf-8", errors="ignore")
        try:
            data = json.loads(raw_data)
        except Exception:
            data = {}

        # --- Log de réception ---
        ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_path = r"C:\Ariane-Agent\logs\sync_inbound.log"
        os.makedirs(os.path.dirname(log_path), exist_ok=True)

        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"[{ts}] SYNC_RECEIVED_RAW: {raw_data}\n")

        # --- Si le payload est vide ou invalide ---
        if not data or "manifest" not in data:
            return jsonify({"status": "error", "reason": "empty_or_invalid_payload"}), 400

        # --- Traitement normal ---
        received_count = len(data.get("manifest", {}))
        summary = {
            "timestamp": ts,
            "agent": data.get("agent", "unknown"),
            "files_count": received_count
        }

        # --- Journaliser la confirmation ---
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"[{ts}] SYNC_PARSED_OK: {json.dumps(summary)}\n")

        return jsonify({"status": "ok", "received": received_count}), 200

    except Exception as e:
        err_msg = f"[MIRROR_ERROR] {e}"
        with open(r"C:\Ariane-Agent\logs\BridgeRuntime.log", "a", encoding="utf-8") as logf:
            logf.write(err_msg + "\n")
        return jsonify({"error": str(e)}), 500

# ===============================================================
# 🧪 DEBUG HMAC – Compare signature attendue / fournie
# ===============================================================
@app.route("/bridge/debug_signature", methods=["POST"])
def debug_signature():
    """Permet de tester la génération HMAC interne SelfGuard"""
    try:
        data = request.get_json(force=True)
        action = data.get("action", "")
        payload = data.get("payload", {})
        nonce = data.get("nonce", "")
        ts = int(data.get("timestamp", 0))
        sig_client = data.get("signature", "")

        key = open(SECRET_PATH, "rb").read().strip()
        concat = f"{action}:{json.dumps(payload, separators=(',', ':'))}:{nonce}:{ts}".encode()
        sig_server = hmac.new(key, concat, hashlib.sha256).hexdigest()

        return jsonify({
            "sig_server": sig_server,
            "sig_client": sig_client,
            "match": sig_server == sig_client
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ===============================================================
# ===============================================================
# 🧩 ENDPOINT : /bridge/sync_cloud  (Phase 28 – Auto-Maintenance)
# ===============================================================
@app.route("/bridge/sync_cloud", methods=["POST"])
def bridge_sync_cloud():
    try:
        payload = request.get_json(force=True)
        mode = payload.get("mode","quick")
        log_path = r"C:\\Ariane-Agent\\logs\\AutoMaintenance.log"
        ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(log_path,"a",encoding="utf-8") as f:
            f.write(f"[{ts}] [sync_cloud] 🔄 Requête reçue (mode={mode})\\n")
        os.system(f'powershell -ExecutionPolicy Bypass -File C:\\Ariane-Agent\\Scripts\\AutoSync.ps1 -Mode {mode}')
        os.system('powershell -ExecutionPolicy Bypass -File C:\\Ariane-Agent\\Scripts\\AutoDeploy.ps1')
        with open(log_path,"a",encoding="utf-8") as f:
            f.write(f"[{ts}] [sync_cloud] ✅ Synchronisation complète terminée\\n")
        return jsonify({"status":"ok","message":"Synchronisation complète terminée."})
    except Exception as e:
        return jsonify({"status":"error","reason":str(e)}),500


if __name__ == '__main__':
    port = int(os.environ.get('BRIDGE_PORT', '5075'))
    print(f"[Bridge] 🟢 Serveur actif sur le port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)


