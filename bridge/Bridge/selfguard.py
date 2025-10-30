# -*- coding: utf-8 -*-
"""
SelfGuard.py – Version stable (Phase 11 + TRACE + DEBUG)
--------------------------------------------------------
- Vérifie les signatures HMAC SHA-256
- Gère les nonces anti-rejeu (TTL 10 min)
- Vérifie le timestamp ±300s
- Vérifie que l’action est autorisée via allowed_actions.json
- Journalise tous les évènements dans BridgeSecurity.log
- TRACE HMAC activé pour la Phase 17
- DEBUG HMAC (trace fichier) activé pour la Phase 27
"""

import os
import json
import time
import uuid
import hmac
import hashlib
import threading
from typing import Any, Dict, Tuple

# === CONFIGURATION ===
BASE_DIR = r"C:\\Ariane-Agent"
SECRETS_PATH = os.path.join(BASE_DIR, "secrets", "bridge_hmac.key")
LOG_DIR = os.path.join(BASE_DIR, "logs")
LOG_SECURITY = os.path.join(LOG_DIR, "BridgeSecurity.log")
NONCES_DB = os.path.join(LOG_DIR, "nonces.json")
ALLOWED_ACTIONS_PATH = os.path.join(BASE_DIR, "Bridge", "allowed_actions.json")

TIMESTAMP_TOLERANCE_SEC = 300  # ±5 minutes
NONCE_TTL = 600  # 10 minutes
_lock = threading.Lock()


class SelfGuard:
    def __init__(self):
        os.makedirs(LOG_DIR, exist_ok=True)
        self.secret = self._load_secret()
        self.allowed = self._load_allowed()

     # === Chargement des ressources ===
    def _load_secret(self) -> bytes:
        if not os.path.exists(SECRETS_PATH):
            raise FileNotFoundError(f"Clé HMAC introuvable : {SECRETS_PATH}")

        with open(SECRETS_PATH, "rb") as f:
            raw = f.read().strip()

        # Si la clé est écrite sous forme hexadécimale (64 caractères), on la convertit
        try:
            txt = raw.decode("utf-8")
            if all(c in "0123456789abcdefABCDEF" for c in txt) and len(txt) % 2 == 0:
                return bytes.fromhex(txt)
        except Exception:
            pass

        return raw

    def _load_allowed(self) -> Dict[str, Any]:
        print(f"[SelfGuard] 🔍 Lecture du fichier d’autorisations : {ALLOWED_ACTIONS_PATH}")
        if not os.path.exists(ALLOWED_ACTIONS_PATH):
            print("[SelfGuard] ⚠️ Fichier introuvable, utilisation d'une liste vide.")
            return {"actions": []}
        with open(ALLOWED_ACTIONS_PATH, "r", encoding="utf-8") as f:
            try:
                return json.load(f)
            except Exception as e:
                print(f"[SelfGuard] ⚠️ Erreur lecture JSON : {e}")
                return {"actions": []}

    # === Gestion des nonces ===
    def _load_nonces(self) -> Dict[str, float]:
        if not os.path.exists(NONCES_DB):
            return {}
        try:
            with open(NONCES_DB, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}

    def _save_nonces(self, data: Dict[str, float]):
        with open(NONCES_DB, "w", encoding="utf-8") as f:
            json.dump(data, f)

    def is_nonce_seen(self, nonce: str) -> bool:
        if not nonce:
            return False
        with _lock:
            data = self._load_nonces()
            return nonce in data

    def register_nonce(self, nonce: str):
        if not nonce:
            return
        with _lock:
            data = self._load_nonces()
            data[nonce] = time.time()
            # purge TTL
            now = time.time()
            expired = [k for k, v in data.items() if now - v > NONCE_TTL]
            for k in expired:
                data.pop(k, None)
            self._save_nonces(data)

        # === Vérification HMAC ===
    def verify(self, action: str, payload: Dict[str, Any], nonce: str, ts: int, signature: str) -> Tuple[bool, str]:
        # 🔍 Trace pour confirmer l'appel
        print(f"[SelfGuard] Vérification déclenchée pour action={action}, nonce={nonce}, ts={ts}")

        # Timestamp check
        now = int(time.time())
        if abs(now - ts) > TIMESTAMP_TOLERANCE_SEC:
            return False, "timestamp_out_of_range"

        # Signature calculation (ordre Python : action|timestamp|nonce|payload)
        calc = self.sign(action, payload, nonce, ts)

        # === TRACE HMAC (console) ===
        print("\n[TRACE HMAC] Vérification de la signature")
        print(f"Message : {action}|{ts}|{nonce}|{json.dumps(payload, sort_keys=True, separators=(',',':'))}")
        print(f"Attendu : {calc}")
        print(f"Reçu    : {signature}\n")

        # === TRACE DANS FICHIER TEMPORAIRE (debug HMAC) ===
        try:
            trace_path = r"C:\Ariane-Agent\logs\HMAC_trace_debug.txt"
            os.makedirs(os.path.dirname(trace_path), exist_ok=True)
            with open(trace_path, "a", encoding="utf-8") as f:
                f.write(f"\n[TRACE HMAC DEBUG]\n")
                f.write(f"Message : {action}|{ts}|{nonce}|{json.dumps(payload, sort_keys=True, separators=(',',':'))}\n")
                f.write(f"Attendu : {calc}\n")
                f.write(f"Reçu    : {signature}\n")
        except Exception as e:
            print(f"[SelfGuard] Erreur écriture trace : {e}")

        if not hmac.compare_digest(calc, signature):
            return False, "invalid_signature"

        # Nonce replay
        if self.is_nonce_seen(nonce):
            return False, "nonce_replay_detected"
        self.register_nonce(nonce)

        # Action autorisée
        if action not in self.allowed.get("actions", []):
            return False, "action_not_allowed"

        return True, "ok"

    # === Journalisation sécurité ===
    def audit(self, entry: Dict[str, Any]) -> None:
        """Écrit une ligne JSON dans BridgeSecurity.log"""
        entry.setdefault("audit_id", str(uuid.uuid4()))
        entry.setdefault("ts", time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()))
        try:
            with open(LOG_SECURITY, "a", encoding="utf-8") as f:
                f.write(json.dumps(entry, ensure_ascii=False) + "\n")
        except Exception:
            pass

    # === Maintenance nonces ===
    def sweep_nonces(self) -> int:
        """Supprime les nonces expirés, retourne le nombre purgé."""
        now = time.time()
        with _lock:
            data = self._load_nonces()
            purged = [k for k, v in data.items() if now - v > NONCE_TTL]
            for k in purged:
                data.pop(k, None)
            self._save_nonces(data)
            return len(purged)

    # ===============================================================
    # ✍️ SIGNATURE HMAC – Génération conforme Bridge ↔ Client
    # ===============================================================
    def sign(self, action: str, payload: dict, nonce: str, ts: int) -> str:
        """Génère une signature HMAC identique à verify() pour les réponses"""
        try:
            # On utilise la même clé secrète que pour verify()
            key = self.secret

            # Format de message aligné avec verify() :
            # action|timestamp|nonce|payload (JSON compacté)
            msg = f"{action}|{ts}|{nonce}|{json.dumps(payload, sort_keys=True, separators=(',', ':'))}"
            digest = hmac.new(key, msg.encode("utf-8"), hashlib.sha256).hexdigest()
            return digest
        except Exception as e:
            print(f"[SelfGuard] Erreur sign() : {e}")
            return "error"
