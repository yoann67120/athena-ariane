# ====================================================================
# 🧠 Invoke-AgentSecure.py – Phase 13.5
# Objectif : envoyer des requêtes HMAC signées au Bridge local (port 5075)
# ====================================================================

import os, hmac, hashlib, json, requests, datetime

BRIDGE_URL = "http://localhost:5075/bridge"
SECRET_PATH = r"C:\\Ariane-Agent\\secrets\\bridge_hmac.key"

def load_key():
    with open(SECRET_PATH, "rb") as f:
        return f.read().strip()

def generate_signature(payload: dict, key: bytes):
    body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    sig = hmac.new(key, body, hashlib.sha256).hexdigest()
    return sig, body

def send_secure(action: str, params: dict = None):
    payload = {
        "protocol": "UsineProtocol_v1",
        "action": action,
        "params": params or {},
        "timestamp": datetime.datetime.utcnow().isoformat()
    }
    key = load_key()
    sig, body = generate_signature(payload, key)
    headers = {"Content-Type": "application/json", "X-HMAC-Signature": sig}
    print(f"📡 Envoi sécurisé → {BRIDGE_URL} (action={action})")
    r = requests.post(BRIDGE_URL, headers=headers, data=body, timeout=10)
    try:
        print("✅ Réponse :", r.json())
    except Exception:
        print("🔍 Réponse brute :", r.text)

if __name__ == "__main__":
    # Test 1 : list_projects
    send_secure("list_projects")

