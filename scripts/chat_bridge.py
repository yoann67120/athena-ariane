# Create an improved chat_bridge file
code = r'''# -*- coding: utf-8 -*-
"""
chat_bridge_improved.py (version Athéna Ready)
Pont CLI -> Agent Flask Ariane
"""

import argparse, datetime, json, os, sys, time, requests
from typing import Optional, Dict
from dotenv import load_dotenv

load_dotenv()

AGENT_EXECUTE_URL_DEFAULT = "http://127.0.0.1:5000/execute"
AGENT_HEALTH_URL_DEFAULT = "http://127.0.0.1:5000/health"
LOG_DIR = r"C:\\Ariane-Agent\\logs"
LOG_FILE = os.path.join(LOG_DIR, "chat_bridge.log")

DEFAULT_TIMEOUT = 120
DEFAULT_RETRIES = 3
ENV_AGENT_SECRET = os.getenv("AGENT_SECRET")

def ensure_dirs(): os.makedirs(LOG_DIR, exist_ok=True)
def log(msg: str):
    ensure_dirs()
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] {msg}")

def make_headers(secret: Optional[str]) -> Dict[str, str]:
    headers = {"Content-Type": "application/json"}
    if secret: headers["X-Agent-Key"] = secret
    return headers

def check_agent(url: str, headers: Dict[str, str]) -> bool:
    try:
        r = requests.get(url, headers=headers, timeout=3)
        return r.status_code == 200
    except Exception:
        return False

def post_with_retries(url, headers, payload, timeout, retries):
    for _ in range(retries):
        try: return requests.post(url, headers=headers, json=payload, timeout=timeout)
        except: time.sleep(2)
    raise RuntimeError("Échec de communication avec l'agent.")

def send_to_agent(prompt, mode, timeout, retries, secret):
    headers = make_headers(secret)
    if not check_agent(AGENT_HEALTH_URL_DEFAULT, headers):
        log("⚠️ Agent non disponible. Lancez : python agent_improved.py")
        return
    payload = {"prompt": prompt}
    log(f"Envoi du prompt → {AGENT_EXECUTE_URL_DEFAULT}")
    r = post_with_retries(AGENT_EXECUTE_URL_DEFAULT, headers, payload, timeout, retries)
    try: data = r.json()
    except: print(r.text); return
    print("\n=== RÉPONSE DE L'AGENT ===")
    print(json.dumps(data, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("prompt", nargs="*", help="Texte à envoyer à l'agent")
    args = parser.parse_args()
    prompt = " ".join(args.prompt) or input("Entrez votre commande : ")
    send_to_agent(prompt, "auto", DEFAULT_TIMEOUT, DEFAULT_RETRIES, ENV_AGENT_SECRET)
'''

with open(os.path.join(os.getcwd(), "chat_bridge_improved.py"), "w", encoding="utf-8") as f:
    f.write(code)

print("✅ Saved chat_bridge_improved.py to current folder")
