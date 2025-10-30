# -*- coding: utf-8 -*-
"""
bridge_server.py – Phase 14.5
Bridge sécurisé reliant AgentKit Cloud ↔ Usine locale + AutoHarmony Sync
"""

import os, json, time, sys, datetime, hmac, hashlib
from flask import Flask, request, jsonify

from selfguard import SelfGuard
from agentkit_router import AgentKitRouter

app = Flask(__name__)
sg = SelfGuard()
router = AgentKitRouter()

LOG_RUNTIME = r"C:\Ariane-Agent\logs\BridgeRuntime.log"
SYNC_LOG = r"C:\Ariane-Agent\logs\sync_inbound.log"
SECRET_PATH = r"C:\Ariane-Agent\secrets\bridge_hmac.key"

# ===============================================================
# ✅ STATUS
# ===============================================================
@app.route('/status', methods=['GET'])
def status():
    try:
        status = {
            "Bridge": "🟢 Actif",
            "HMAC": "✅ OK",
            "Logs": True,
            "Port": int(os.environ.get('BRIDGE_PORT', '5075')),
            "SelfGuard": "✅ Chargé",
            "TimestampTolerance": "±300s"
        }
        return jsonify(status)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ===============================================================
# 🔐 BRIDGE PRINCIPAL
# ===============================================================
@app.route('/bridge', methods=['POST'])
@app.route('/agentkit/command', methods=['POST'])
def bridge():
    """Réception d’un ordre signé provenant du Cloud GPT/AgentKit"""
    t0 = time.time()
    data = request.get_json(silent=True) or {}
    action = data.get('action')
    payload = data.get('payload', {})

    signature = request.headers.get('X-HMAC', '')
    nonce = request.headers.get('X-Nonce', '')
    try:
        ts = int(request.headers.get('X-Timestamp', '0'))
    except Exception:
        ts = 0

    ok, reason = sg.verify(action or '', payload, nonce, ts, signature)
    audit = {
        "time": int(time.time()),
        "endpoint": "/bridge",
        "action": action,
        "nonce": nonce,
        "timestamp": ts,
        "client_ip": request.remote_addr,
        "verify": reason
    }

    if not ok:
        sg.audit({**audit, "result": "rejected"})
        return jsonify({"error": reason}), 401

    result = router.handle(action, payload)
    sg.audit({**audit, "result": result.get('status', 'unknown'),
              "latency_ms": int((time.time() - t0) * 1000)})

    try:
        os.makedirs(os.path.dirname(LOG_RUNTIME), exist_ok=True)
        with open(LOG_RUNTIME, 'a', encoding='utf-8') as f:
            f.write(json.dumps({
                "t": int(time.time()),
                "action": action,
                "result": result.get('status')
            }) + "\n")
    except Exception:
        pass

    return jsonify(result)

# ===============================================================
# 🌐 SYNC ENDPOINT – AutoPilot / AutoHarmony
# ===============================================================
def verify_hmac(payload, signature):
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
        if not verify_hmac(payload, signature):
            return jsonify({"error": "invalid_signature"}), 401

        os.makedirs(os.path.dirname(SYNC_LOG), exist_ok=True)
        ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(SYNC_LOG, "a", encoding="utf-8") as f:
            f.write(f"[{ts}] SYNC_RECEIVED: {json.dumps(payload)}\n")

        return jsonify({"status": "received", "timestamp": ts})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ===============================================================
if __name__ == '__main__':
    port = int(os.environ.get('BRIDGE_PORT', '5075'))
    print(f"[Bridge] 🟢 Serveur actif sur le port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)
