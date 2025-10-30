import os, json, hmac, hashlib, time, requests
from datetime import datetime

BASE_URL = "https://ariane.ngrok.io/bridge"
SECRET_PATH = r"C:\Ariane-Agent\secrets\bridge_hmac.key"
LOG_PATH = r"C:\Ariane-Agent\logs\\AgentRelay.log"

def log(msg):
    ts = datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")
    print(f"{ts} {msg}")
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(f"{ts} {msg}\\n")

def sign_request(action, payload, nonce, ts):
    """Signature 100 % identique à SelfGuard.sign(), avec décodage hex"""
    raw = open(SECRET_PATH, "rb").read().strip()
    try:
        txt = raw.decode("utf-8")
        # Si la clé est une chaîne hexadécimale, on la convertit
        if all(c in "0123456789abcdefABCDEF" for c in txt) and len(txt) % 2 == 0:
            key = bytes.fromhex(txt)
        else:
            key = raw
    except Exception:
        key = raw

    msg = f"{action}|{ts}|{nonce}|{json.dumps(payload, separators=(',', ':'))}"
    digest = hmac.new(key, msg.encode("utf-8"), hashlib.sha256).hexdigest()
    print(f"\n[DEBUG CLIENT] Message signé : {msg}")
    print(f"[DEBUG CLIENT] Signature envoyée : {digest}\n")
    return digest


def send_action(action, payload):
    nonce = os.urandom(8).hex()
    ts = int(time.time())
    sig = sign_request(action, payload, nonce, ts)
    headers = {
        "X-HMAC": sig,
        "X-Nonce": nonce,
        "X-Timestamp": str(ts),
        "Content-Type": "application/json"
    }
    body = {"action": action, "payload": payload}
    try:
        log(f"🌍 Envoi vers {BASE_URL} → {action}")
        r = requests.post(BASE_URL, json=body, headers=headers, timeout=30)
        log(f"✅ Statut {r.status_code}: {r.text[:300]}")
        return r.json()
    except Exception as e:
        log(f"❌ Erreur : {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    log("=== TEST RELAIS CLOUD → BRIDGE LOCAL (PATCH v27.5) ===")
    result = send_action("create_project", {"name": "Auto_Test_01"})
    log(f"Résultat : {json.dumps(result, ensure_ascii=False)}")
    log("=== FIN TEST ===")
