# -*- coding: utf-8 -*-
"""
agentkit_router.py – Phase 11
Routage des actions vers l’Usine à Projets (Flask locale)
"""

import requests
import os
import json
from typing import Dict, Any


class AgentKitRouter:
    """Route les actions vers l’Usine à Projets (Flask) locale."""

    def __init__(self):
        # URL de base de l’Usine Flask
        self.base_url = os.environ.get("USINE_BASE", "http://127.0.0.1:5050")

    def handle(self, action: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Envoie l’action vers le bon endpoint de l’Usine."""
        try:
            if action == "list_projects":
                r = requests.get(f"{self.base_url}/list", timeout=20)
                return {"status": "ok", "data": r.json()}

            elif action == "create_project":
                r = requests.post(f"{self.base_url}/create", json=payload, timeout=30)
                return {"status": "ok", "data": r.json()}

            elif action == "deploy_project":
                r = requests.post(f"{self.base_url}/deploy", json=payload, timeout=60)
                return {"status": "ok", "data": r.json()}

            elif action == "update_project":
                r = requests.post(f"{self.base_url}/update", json=payload, timeout=30)
                return {"status": "ok", "data": r.json()}

            else:
                return {"status": "error", "error": f"unknown_action: {action}"}

        except Exception as e:
            return {"status": "error", "error": str(e)}
