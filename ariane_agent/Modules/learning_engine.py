# ====================================================================
# 🧩 ARIANE V4 – MODULE LEARNING_ENGINE (Phase 20)
# Analyse les logs AutoHarmony + AutoMaintenance
# et génère un plan d'évolution (EvolutionPlan.json)
# ====================================================================

import os, json, re, statistics, psutil
from datetime import datetime

BASE_DIR   = r"C:\Ariane-Agent"
LOG_DIR    = os.path.join(BASE_DIR, "logs")
HARMONY_LOG= os.path.join(LOG_DIR, "AutoHarmony.log")
MAINT_LOG  = os.path.join(LOG_DIR, "AutoMaintenance.log")
PLAN_PATH  = os.path.join(LOG_DIR, "EvolutionPlan.json")

def log(msg):
    with open(os.path.join(LOG_DIR,"AutoLearning.log"),"a",encoding="utf-8") as f:
        f.write(f"[{datetime.now()}] {msg}\n")

def parse_metrics():
    cpu,ram=[],[]
    try:
        with open(HARMONY_LOG,"r",encoding="utf-8") as f:
            for line in f:
                if "cpu" in line.lower() or "ram" in line.lower(): continue
        # Lecture brute CPU/RAM non disponible → utiliser charge actuelle
        cpu.append(psutil.cpu_percent(interval=1))
        ram.append(psutil.virtual_memory().percent)
    except Exception as e:
        log(f"[ERREUR] lecture harmony: {e}")
    return (statistics.mean(cpu) if cpu else psutil.cpu_percent(),
            statistics.mean(ram) if ram else psutil.virtual_memory().percent)

def parse_maintenance():
    issues=[]
    if not os.path.exists(MAINT_LOG): return issues
    with open(MAINT_LOG,"r",encoding="utf-8") as f:
        for line in f:
            if "erreur" in line.lower() or "fail" in line.lower():
                issues.append(line.strip())
    return issues[-5:]

def generate_plan():
    cpu,ram = parse_metrics()
    issues  = parse_maintenance()
    plan={
        "timestamp": datetime.now().isoformat(),
        "avg_cpu": cpu,
        "avg_ram": ram,
        "issues_detected": len(issues),
        "actions":[]
    }
    if cpu>85 or ram>85:
        plan["actions"].append("Reduce non-critical task frequency")
    if len(issues)>0:
        plan["actions"].append("Trigger self-repair via AgentKit")
    if cpu<60 and ram<60 and len(issues)==0:
        plan["actions"].append("Boost learning rate + enable extended tasks")
    with open(PLAN_PATH,"w",encoding="utf-8") as f:
        json.dump(plan,f,indent=4)
    log(f"🧠 Plan généré : {PLAN_PATH}")
    return plan

if __name__=="__main__":
    log("=== DÉMARRAGE LEARNING_ENGINE ===")
    plan=generate_plan()
    log(json.dumps(plan,indent=2))
    log("=== FIN LEARNING_ENGINE ===")
