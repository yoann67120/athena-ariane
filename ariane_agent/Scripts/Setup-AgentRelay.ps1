# ====================================================================
# 🚀 ARIANE V4 - PHASE 27 : INSTALLATION RELAIS CLOUD ↔ LOCAL
# Auteur : Yoann Rousselle
# Description : Crée le client HMAC Python et exécute un test automatique
# ====================================================================

$BaseDir = "C:\Ariane-Agent"
$RelayDir = "$BaseDir\BridgeRelay"
$SecretsDir = "$BaseDir\secrets"
$LogsDir = "$BaseDir\logs"
$KeyPath = "$SecretsDir\bridge_hmac.key"
$RelayFile = "$RelayDir\agentkit_hmac_client.py"
$BridgeURL = "https://usine.ngrok.io/bridge"

# --- Vérif préliminaire ---
Write-Host "`n🔍 Vérification de l'environnement..." -ForegroundColor Cyan
if (!(Test-Path $KeyPath)) { Write-Host "❌ Clé HMAC introuvable : $KeyPath" -ForegroundColor Red; exit 1 }
if (!(Test-Path $RelayDir)) { New-Item -ItemType Directory -Path $RelayDir | Out-Null }
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir | Out-Null }

# --- Création du fichier Python ---
Write-Host "⚙️ Création du client relais Python..." -ForegroundColor Yellow
@"
# ====================================================================
# 🚀 ARIANE V4 - AGENTKIT HMAC CLIENT (v27.1)
# Relais Cloud → Local : signe et transmet les actions vers le Bridge
# ====================================================================

import os, json, hmac, hashlib, time, requests, sys
from datetime import datetime

BASE_URL = os.environ.get("BRIDGE_URL", "$BridgeURL")
SECRET_PATH = r"$KeyPath"
LOG_PATH = r"$LogsDir\\AgentRelay.log"

def log(msg: str):
    ts = datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")
    line = f"{ts} {msg}"
    print(line)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(line + "\\n")

def sign_request(action: str, payload: dict):
    key = open(SECRET_PATH, "rb").read().strip()
    nonce = os.urandom(8).hex()
    ts = int(time.time())
    data = f"{action}:{json.dumps(payload, separators=(',', ':'))}:{nonce}:{ts}".encode("utf-8")
    signature = hmac.new(key, data, hashlib.sha256).hexdigest()
    return signature, nonce, ts

def send_action(action: str, payload: dict):
    sig, nonce, ts = sign_request(action, payload)
    headers = {
        "X-HMAC": sig,
        "X-Nonce": nonce,
        "X-Timestamp": str(ts),
        "Content-Type": "application/json"
    }
    body = json.dumps({"action": action, "payload": payload})
    try:
        log(f"🌍 Envoi vers {BASE_URL} → {action}")
        r = requests.post(BASE_URL, data=body, headers=headers, timeout=30)
        log(f"✅ Statut {r.status_code}: {r.text[:200]}")
        return r.json()
    except Exception as e:
        log(f"❌ Erreur d'envoi : {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    test_action = {"action": "create_project", "payload": {"name": "Auto_Test_01"}}
    log("=== TEST RELAIS CLOUD → BRIDGE LOCAL ===")
    result = send_action(test_action["action"], test_action["payload"])
    log(f"Résultat : {json.dumps(result, ensure_ascii=False)}")
    log("=== FIN TEST ===")
"@ | Out-File -FilePath $RelayFile -Encoding utf8

# --- Exécution du test ---
Write-Host "`n🚀 Test du relais Cloud → Bridge local..." -ForegroundColor Green
python $RelayFile

Write-Host "`n✅ Test terminé. Vérifie le fichier de log :" -ForegroundColor Cyan
Write-Host "$LogsDir\AgentRelay.log" -ForegroundColor Yellow
Write-Host "`n🧠 Si tout est OK, la réponse du Bridge doit contenir : 'Project created successfully'"
