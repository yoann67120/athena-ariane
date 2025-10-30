# ====================================================================
# ⚙️ AgentKit.Actions – Initialisation
# Auteur : Yoann Rousselle
# Objectif : charger automatiquement les fichiers d’action (.py)
# ====================================================================

import os
import importlib

# Dossier contenant les actions
BASE_DIR = os.path.dirname(__file__)

# Parcours tous les fichiers Python de ce dossier (sauf __init__)
for filename in os.listdir(BASE_DIR):
    if filename.endswith(".py") and filename != "__init__.py":
        module_name = f"agentkit.actions.{filename[:-3]}"
        importlib.import_module(module_name)
