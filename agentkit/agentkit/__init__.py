# ====================================================================
# 🧩 AgentKit – Core Loader (v2.0 stable)
# Auteur : Yoann Rousselle
# Description : Moteur central de chargement et d’exécution des actions
# ====================================================================

import os
import importlib
import pkgutil
import sys

BASE_DIR = os.path.dirname(__file__)
ACTIONS_DIR = os.path.join(BASE_DIR, "actions")

if not os.path.exists(ACTIONS_DIR):
    raise FileNotFoundError(f"⚠️ Dossier 'actions' introuvable : {ACTIONS_DIR}")

# Ajout du dossier actions au sys.path pour import direct
if ACTIONS_DIR not in sys.path:
    sys.path.append(ACTIONS_DIR)

ACTIONS = {}

def load_actions():
    """Charge dynamiquement toutes les actions disponibles dans agentkit/actions."""
    global ACTIONS
    for _, name, _ in pkgutil.iter_modules([ACTIONS_DIR]):
        module_name = f"agentkit.actions.{name}"
        module = importlib.import_module(module_name)
        ACTIONS[name] = module
    print(f"[AgentKit] 🔗 {len(ACTIONS)} actions chargées : {', '.join(ACTIONS.keys())}")

def run_action(action_name: str, params=None, **kwargs):
    """
    Exécute une action AgentKit.
    Appelle automatiquement la fonction run(params) de l’action spécifiée.
    """
    if action_name not in ACTIONS:
        raise ValueError(f"Action inconnue : {action_name}")

    module = ACTIONS[action_name]

    # Fusionne params et kwargs dans un seul dict
    merged = {}
    if params and isinstance(params, dict):
        merged.update(params)
    merged.update(kwargs)

    # Si le module possède une fonction 'run', on l'exécute
    if hasattr(module, "run"):
        try:
            result = module.run(merged)
            return result
        except Exception as e:
            return {"error": str(e)}
    else:
        return {"error": f"L’action '{action_name}' ne contient pas de fonction 'run'."}

# Chargement initial de toutes les actions au démarrage
load_actions()
