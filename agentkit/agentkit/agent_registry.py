# ====================================================================
# 🧩 AgentKit – Registre Dynamique d’Actions
# Fichier : C:\Ariane-Agent\agentkit\agent_registry.py
# Objectif : Charger automatiquement les actions autorisées depuis agentkit_config.json
# ====================================================================

import os
import json
import datetime

CONFIG_PATH = r"C:\Ariane-Agent\agentkit_config.json"
LOG_PATH = r"C:\Ariane-Agent\logs\agentkit_init.log"

def log(msg: str):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(f"[{timestamp}] {msg}\n")
    print(msg)

def load_agentkit_config():
    """Charge et valide la configuration d’AgentKit"""
    if not os.path.exists(CONFIG_PATH):
        log(f"❌ Fichier de configuration introuvable : {CONFIG_PATH}")
        return None

    try:
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            config = json.load(f)
        log(f"✅ Configuration AgentKit v{config.get('version')} chargée.")
        log(f"🔗 Agent : {config.get('agent_name')}")
        log("📦 Actions détectées :")
        for name, details in config["actions"].items():
            status = "✅ Activée" if details.get("enabled") else "❌ Désactivée"
            log(f"   → {name} [{status}]")
        return config
    except Exception as e:
        log(f"⚠️ Erreur lors du chargement : {e}")
        return None

def register_actions(config):
    """Construit un registre Python des actions disponibles"""
    registry = {}
    if not config:
        return registry

    for action_name, info in config["actions"].items():
        if info.get("enabled"):
            path = info["path"]
            if os.path.exists(path):
                registry[action_name] = path
                log(f"🧩 Action enregistrée : {action_name} → {path}")
            else:
                log(f"⚠️ Fichier introuvable pour l’action : {action_name}")
    log(f"✅ Registre initialisé ({len(registry)} actions).")
    return registry

if __name__ == "__main__":
    log("=== Initialisation AgentKit (registre dynamique) ===")
    cfg = load_agentkit_config()
    registry = register_actions(cfg)
    log("=== Chargement terminé ===")
