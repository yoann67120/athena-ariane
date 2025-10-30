# -*- coding: utf-8 -*-
# Phase 10.3 – Status + Nettoyage final

import os, time, hmac, hashlib, importlib.util
from flask import Flask, request, jsonify

BRIDGE_PORT = int(os.getenv("BRIDGE_PORT", "5075"))
BASE_DIR    = r"C:\Ariane-Agent"
BRIDGE_DIR  = os.path.dirname(__file__)
SECRET_FILE = os.path.join(BASE_DIR, "secrets", "bridge_hmac.key")
TIMESTAMP_SKEW = 300

# --- Chargement SelfGuard ---
SELF_GUARD_PATH = os.path.join(BRIDGE_DIR, "SelfGuard.py")
spec = importlib.util.spec_from_file_location("SelfGuard", SELF_GUARD_PATH)
SelfGuard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(SelfGuard)

log_security   = SelfGuard.log_security
is_action_allowed = SelfGuard.is_action_allowed
is_nonce_seen  = SelfGuard.is_nonce_seen
register_nonce = SelfGuard.register_nonce
sweep_nonces   = SelfGuard.sweep_nonces

app = Flask(__name__)

def load_secret() -> bytes:
    raw = open(SECRET_FILE, "r", encoding="ascii").read().strip()
    try:    return bytes.fromhex(raw)
    except: return raw.encode("utf-8")

def sha256_hex(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

def sign(secret: bytes, ts: str, action: str, body: bytes) -> str:
    body_hash = sha256_hex(body or b"")
    msg = f"{ts}\n{action}\n{body_hash}".encode("utf-8")
    return hmac.new(secret, msg, hashlib.sha256).hexdigest()

def verify(headers, body: bytes):
    xsig   = headers.get("X-Signature")
    xts    = headers.get("X-Timestamp")
    xact   = headers.get("X-Action")
    xnonce = headers.get("X-Nonce")
    body_hash = sha256_hex(body or b"")

    # Vérifications
    if not all([xsig, xts, xact, xnonce]):
        log_security("reject_missing_headers", {"ip": request.remote_addr})
        return False, "missing_headers", body_hash
    if is_nonce_seen(xnonce):
        log_security("reject_replay", {"ip": request.remote_addr, "nonce": xnonce})
        return False, "replay_detected", body_hash
    try: ts = int(xts)
    except: return False, "invalid_timestamp", body_hash
    if abs(int(time.time()) - ts) > TIMESTAMP_SKEW:
        return False, "timestamp_skew", body_hash
    expected = sign(load_secret(), xts, xact, body or b"")
    if not hmac.compare_digest(xsig, expected):
        return False, "invalid_signature", body_hash
    register_nonce(xnonce)
    if not is_action_allowed(xact):
        return False, "action_not_allowed", body_hash
    log_security("accept", {"ip": request.remote_addr, "action": xact})
    return True, "", body_hash

@app.route("/bridge", methods=["POST"])
def bridge():
    sweep_nonces()
    body = request.get_data() or b""
    ok, err, _ = verify(request.headers, body)
    if not ok:
        return jsonify({"action": request.headers.get("X-Action"), "error": err}), 401
    data = request.get_json(silent=True) or {}
    action = request.headers.get("X-Action") or data.get("action", "unknown")
    return jsonify({
        "action": action,
        "error": None,
        "protocol": "UsineProtocol_v1",
        "result": {"status": "ok", "message": f"Action '{action}' exécutée (SelfGuard OK)."}
    }), 200

@app.route("/status", methods=["GET"])
def status():
    try:
        secret = load_secret()
        secret_ok = len(secret) > 0
    except:
        secret_ok = False
    state = {
        "Bridge": "🟢 Actif",
        "HMAC": "✅ OK" if secret_ok else "❌ Absent",
        "SelfGuard": "✅ Chargé",
        "Logs": os.path.exists(os.path.join(BASE_DIR, "logs", "BridgeSecurity.log")),
        "TimestampTolerance": f"±{TIMESTAMP_SKEW}s",
        "Port": BRIDGE_PORT
    }
    return jsonify(state)

if __name__ == "__main__":
    print(f"[Bridge] ✅ Sécurité complète – http://localhost:{BRIDGE_PORT}")
    app.run(host="0.0.0.0", port=BRIDGE_PORT, debug=False)
