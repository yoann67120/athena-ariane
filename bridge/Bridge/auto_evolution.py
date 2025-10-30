# ====================================================================
# 🤖  ARIANE V4 – AUTOEVOLUTION v1
# Auteur : Yoann Rousselle
# Description : analyse les logs d’Athena et génère learn_queue.json
# ====================================================================

import os, json, datetime, re

LOG_DIR = r"C:\Ariane-Agent\logs"
AUTOEVO_DIR = os.path.join(LOG_DIR, "AutoEvolution")
GLOBAL_LOG = os.path.join(LOG_DIR, "Global.log")
LEARN_QUEUE = os.path.join(AUTOEVO_DIR, "learn_queue.json")

os.makedirs(AUTOEVO_DIR, exist_ok=True)

def now():
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def read_global_log():
    if not os.path.isfile(GLOBAL_LOG):
        return []
    with open(GLOBAL_LOG, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()[-500:]
    return lines

def detect_patterns(lines):
    results = []
    for l in lines:
        if "error" in l.lower() or "failed" in l.lower():
            results.append({"timestamp": now(), "level": "error", "message": l.strip()})
        if "restart" in l.lower():
            results.append({"timestamp": now(), "level": "action", "message": l.strip()})
    return results

def write_queue(entries):
    queue = {"generated_at": now(), "entries": entries, "summary": {"total": len(entries)}}
    with open(LEARN_QUEUE, "w", encoding="utf-8") as f:
        json.dump(queue, f, indent=2, ensure_ascii=False)
    print(f"✅ learn_queue.json mis à jour ({len(entries)} événements)")

def main():
    lines = read_global_log()
    entries = detect_patterns(lines)
    write_queue(entries)

if __name__ == "__main__":
    main()
