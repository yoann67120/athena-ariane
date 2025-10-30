# ====================================================================
# Analyze-GlobalLog.py - Phase 8.5 AutoEvolution v1
# Analyse du Global.log et création du fichier learn_queue.json
# ====================================================================

import json, os, re, datetime

LOG = r"C:\Ariane-Agent\logs\Global.log"
OUT = r"C:\Ariane-Agent\logs\AutoEvolution\learn_queue.json"

def parse_line(line):
    # [2025-10-28 12:34:56] [Monitor] texte
    m = re.match(r"\[(.*?)\] \[Monitor\] (.*)", line)
    if not m:
        return None
    ts, msg = m.groups()
    level = "info"
    if "DOWN détecté" in msg or "ECHEC" in msg or "ERREUR" in msg:
        level = "error"
    elif "Relance" in msg:
        level = "action"
    return {"timestamp": ts, "message": msg, "level": level}

# --- Lecture du log ---
os.makedirs(os.path.dirname(OUT), exist_ok=True)
items = []

if os.path.exists(LOG):
    with open(LOG, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            p = parse_line(line.strip())
            if p:
                items.append(p)

# --- Résumé ---
summary = {
    "total": len(items),
    "errors": sum(1 for i in items if i["level"] == "error"),
    "actions": sum(1 for i in items if i["level"] == "action"),
    "last": items[-1] if items else None,
}

payload = {
    "generated_at": datetime.datetime.now().isoformat(),
    "items": items[-500:],
    "summary": summary
}

with open(OUT, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)

print("✅ AutoEvolution queue générée :", OUT)
