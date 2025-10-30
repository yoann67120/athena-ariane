# ====================================================================
# 🤝  ARIANE V4 – PHASE 9.3
# Synchronisation Cloud ↔ Local pour AutoEvolution
# Auteur : Yoann Rousselle
# ====================================================================

import os, json, datetime, re

LOGS_DIR = r"C:\Ariane-Agent\logs"
AUTO_DIR = os.path.join(LOGS_DIR, "AutoEvolution")
LEARN_FILE = os.path.join(AUTO_DIR, "learn_queue.json")
REPORT_FILE = os.path.join(AUTO_DIR, "report.json")

def now():
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def read_learn_queue():
    if not os.path.isfile(LEARN_FILE):
        return {"error": "learn_queue_missing"}
    with open(LEARN_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def analyze(entries):
    report = {
        "generated_at": now(),
        "summary": {"errors": 0, "actions": 0, "modules": {}},
        "insights": []
    }
    for e in entries:
        msg = e.get("message", "").lower()
        if "error" in e.get("level", ""):
            report["summary"]["errors"] += 1
        if "restart" in msg or "relance" in msg:
            report["summary"]["actions"] += 1
        mod = re.findall(r"\[(.*?)\]", e.get("message", ""))
        for m in mod:
            report["summary"]["modules"][m] = report["summary"]["modules"].get(m, 0) + 1
    report["insights"].append(
        f"{report['summary']['errors']} erreurs détectées et "
        f"{report['summary']['actions']} actions déclenchées sur {len(report['summary']['modules'])} modules."
    )
    return report

def main():
    data = read_learn_queue()
    if "entries" not in data:
        print("❌ Aucune donnée à analyser.")
        return
    report = analyze(data["entries"])
    with open(REPORT_FILE, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    print(f"✅ Rapport généré : {REPORT_FILE}")

if __name__ == "__main__":
    main()
