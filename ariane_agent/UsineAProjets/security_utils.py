# ====================================================================
# 🔐 SECURITY UTILS – Usine à Projets
# Auteur : Yoann Rousselle
# Description : Génération et vérification de signatures HMAC-SHA256
# ====================================================================

import os
import hmac
import hashlib
import datetime

LOG_FILE = r"C:\Ariane-Agent\logs\security.log"
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

def log_security(msg: str):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{ts}] {msg}\n")

def generate_signature(secret_key: str, payload: str) -> str:
    """Crée une signature HMAC-SHA256 à partir du corps JSON brut"""
    signature = hmac.new(
        secret_key.encode('utf-8'),
        msg=payload.encode('utf-8'),
        digestmod=hashlib.sha256
    ).hexdigest()
    log_security(f"🟢 Signature générée : {signature[:12]}...")
    return signature

def verify_signature(secret_key: str, payload: str, signature: str) -> bool:
    """Vérifie la signature reçue"""
    expected = generate_signature(secret_key, payload)
    match = hmac.compare_digest(expected, signature)
    if match:
        log_security("✅ Signature vérifiée avec succès.")
    else:
        log_security(f"❌ Signature invalide ! attendu={expected[:12]} reçu={signature[:12]}")
    return match
