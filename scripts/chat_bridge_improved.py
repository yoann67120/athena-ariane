# -*- coding: utf-8 -*-
"""
chat_bridge_improved.py (version Athéna Ready)
Pont CLI -> Agent Flask Ariane

✔ Affichage propre (stdout / stderr / exit_code / temps)
✔ Lecture JSON (r.json())
✔ Mode --raw pour voir la réponse brute
✔ Retente automatiquement en cas d’erreur réseau
✔ Compatible Windows local et environnement OpenAI Builder
"""

import argparse
import datetime
import json
import os
import sys
import time
from typing import Optional, Dict
import requests
from dotenv import load_dotenv

# ======================================
# CONFIGURATION DE BASE
# ======================================
load_dotenv()

AGENT_EXECUTE_URL_DEFAULT = "http://127.0.0.1:5000/execute"
AGENT_HEALTH_URL_DEFAULT = "http://127.0.0.1:5000/health"
LOG_DIR = r"C:\\Ariane-Agent\\logs"
LOG_FILE = os.path.join(LOG_DIR, "chat_bridge.log")

DEFAULT_TIMEOUT = 120
DEFAULT_RETRIES = 3
ENV_AGENT_SECRET = os.getenv("AGENT_SECRET")


# ======================================
# OUTILS DE LOG ET UTILITAIRES
# ======================================
def ensure_dirs():
    os.makedirs(LOG_DIR, exist_ok=True)


def log(msg: str):
    ensure_dirs()
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass


def make_headers(secret: Optional[str]) -> Dict[str, str]:
    headers = {"Content-Type": "application/json"}
    if secret:
        headers["X-Agent-Key"] = secret
    return headers


def check_agent(url: str, headers: Dict[str, str]) -> bool:
    try:
        r = requests.get(url, headers=headers, timeout=3)
        return r.status_code == 200
    except Exception:
        return False


def post_with_retries(url: str, headers: Dict[str, str], payload: dict, timeout: int, retries: int):
    last_exc = None
    for attempt in range(1, retries + 1):
        try:
            return requests.post(url, headers=headers, json=payload, timeout=timeout)
        except requests.exceptions.RequestException as e:
            last_exc = e
            log(f"Tentative {attempt}/{retries} échouée : {e}")
            time.sleep(min(2 ** attempt, 8))
    raise last_exc if last_exc else RuntimeError("Erreur réseau inconnue")


# ======================================
# AFFICHAGE DE LA RÉPONSE (JSON)
# ======================================
def display_response(data: dict):
    """Affiche la réponse structurée (Athéna Ready)."""
    print("\n=== RÉPONSE DE L'AGENT ===")

    if "message" in data and data["message"]:
        print("\n[Message]")
        print(data["message"])

    if "stdout" in data and data["stdout"]:
        print("\n[Sortie]")
        print(data["stdout"])

    if "stderr" in data and data["stderr"]:
        print("\n[Erreurs]")
        print(data["stderr"])

    if "execution_time" in data:
        print(f"\n[Durée] {data['execution_time']}s")

    if "exit_code" in data:
        print(f"\n[Code de sortie] {data['exit_code']}")


# ======================================
# ENVOI AU SERVEUR AGENT
# ======================================
def send_to_agent(prompt: str, mode: str, raw: bool, timeout: int, retries: int, secret: Optional[str]) -> int:
    headers = make_headers(secret)

    # Vérifier la disponibilité de l’agent
    if not check_agent(AGENT_HEALTH_URL_DEFAULT, headers):
        log("⚠️ Agent Ariane non disponible. Lancez : python agent_improved.py")
        return 1

    payload = {"prompt": prompt}
    log(f"Envoi du prompt (mode={mode}) → agent : {AGENT_EXECUTE_URL_DEFAULT}")

    try:
        r = post_with_retries(AGENT_EXECUTE_URL_DEFAULT, headers, payload, timeout, retries)
    except Exception as e:
        log(f"Erreur réseau après {retries} tentatives : {e}")
        return 1

    # En mode brut → afficher directement la réponse JSON brute
    if raw:
        print("\n=== RÉPONSE BRUTE ===")
        print(r.text)
        return 0

    # Sinon → parser le JSON proprement
    try:
        data = r.json()
    except ValueError:
        log("⚠️ Réponse non-JSON reçue de l'agent : affichage brut.")
        print("\n--- Réponse brute ---")
        print(r.text)
        return 1

    # Affichage lisible et structuré
    display_response(data)
    log("Réponse affichée avec succès.")
    return 0


# ======================================
# MAIN CLI
# ======================================
def main(argv: Optional[list] = None) -> int:
    parser = argparse.ArgumentParser(description="Chat Bridge Ariane (version Athéna Ready)")
    parser.add_argument("prompt", nargs="*", help="Texte ou commande à envoyer à l'agent")
    parser.add_argument("--mode", choices=["auto", "text", "code"], default="auto", help="Mode d'interprétation")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT, help="Timeout de la requête (s)")
    parser.add_argument("--retries", type=int, default=DEFAULT_RETRIES, help="Nombre de tentatives réseau")
    parser.add_argument("--secret", default=ENV_AGENT_SECRET, help="Clé secrète (AGENT_SECRET)")
    parser.add_argument("--raw", action="store_true", help="Afficher la réponse JSON brute (debug)")

    args = parser.parse_args(argv)
    prompt = " ".join(args.prompt).strip() if args.prompt else input("Entrez votre commande : ").strip()

    if not prompt:
        log("Aucun prompt fourni.")
        return 1

    return send_to_agent(
        prompt=prompt,
        mode=args.mode,
        raw=args.raw,
        timeout=args.timeout,
        retries=args.retries,
        secret=args.secret,
    )


if __name__ == "__main__":
    sys.exit(main())
