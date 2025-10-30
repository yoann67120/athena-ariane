# ====================================================================
# 🧩 USINEPROTOCOL v1 – Format standard de communication Ariane
# Auteur : Yoann Rousselle
# Description : Définit la structure JSON unifiée pour toutes les requêtes
# ====================================================================

import datetime
import json
import os

LOG_FILE = r"C:\Ariane-Agent\logs\usine_protocol.log"
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

def log_protocol(msg: str):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{ts}] {msg}\n")

def build_request(source: str, action: str, params: dict, context: dict = None):
    """Construit un paquet UsineProtocol prêt à envoyer à l’Usine"""
    packet = {
        "protocol": "UsineProtocol_v1",
        "source": source,
        "action": action,
        "params": params or {},
        "context": context or {},
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
    }
    log_protocol(f"🟦 Build request: {packet}")
    return packet

def parse_request(data: dict):
    """Analyse et valide un paquet UsineProtocol entrant"""
    if not isinstance(data, dict):
        raise ValueError("Requête non valide (pas un JSON)")
    if data.get("protocol") != "UsineProtocol_v1":
        raise ValueError("Protocole inconnu ou manquant")
    log_protocol(f"🟩 Requête valide : {data.get('action')}")
    return {
        "source": data.get("source", "unknown"),
        "action": data.get("action"),
        "params": data.get("params", {}),
        "context": data.get("context", {}),
        "timestamp": data.get("timestamp")
    }

def build_response(status: str, action: str, result=None, error=None):
    """Construit la réponse standardisée"""
    packet = {
        "protocol": "UsineProtocol_v1",
        "status": status,
        "action": action,
        "result": result,
        "error": error,
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
    }
    log_protocol(f"⬛ Build response: {packet}")
    return packet
