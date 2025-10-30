# ====================================================================
# 🚀 PATCH V27.5 : ALIGNEMENT PARFAIT HMAC CLIENT ↔ SELF GUARD
# Auteur : Yoann Rousselle
# Objectif : Reproduire la signature "4d2151..." exactement
# ====================================================================

$RelayFile = "C:\Ariane-Agent\BridgeRelay\agentkit_hmac_client.py"
$KeyPath = "C:\Ariane-Agent\secrets\bridge_hmac.key"
$LogsDir = "C:\Ariane-Agent\logs"
$BridgeURL = "https://usine.ngrok.io/bridge"

@"
import os, json, hmac, hashlib, time, requests
from datetime import datetime

BASE_URL = "$BridgeURL"
SECRET_PATH = r"$KeyPath"
LOG_PATH = r"$LogsDir\\AgentRelay.log"

def log(msg):
    ts = datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")
    print(f"{ts} {msg}")
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(f"{ts} {msg}\\n")

def sign_request(action, payload, nonce, ts):
    """Signature alignée sur SelfGuard.verify()"""
    key = open(SECRET_PATH, "rb").read().strip()
    concat = f"{action}:{json.dumps(payload, separators=(',', ':'))}:{nonce}:{ts}".encode()
    return hmac.new(key, concat, hashlib.sha256).hexdigest()

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
"@ | Out-File -FilePath $RelayFile -Encoding utf8

# --- Test immédiat ---
Write-Host "`n🚀 Test du relais Cloud → Bridge (v27.5)..." -ForegroundColor Green
python $RelayFile
