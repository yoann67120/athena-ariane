# ====================================================================
# 🧩 ARIANE V4 - MODULE AUTO_ADAPT (Phase 21)
# Analyse le plan d'évolution et ajuste priorités & fréquences
# ====================================================================

import os, json, psutil, subprocess, time, hmac, hashlib, requests
from datetime import datetime

BASE_DIR   = r"C:\Ariane-Agent"
LOG_DIR    = os.path.join(BASE_DIR,"logs")
PLAN_PATH  = os.path.join(LOG_DIR,"EvolutionPlan.json")
LOG_PATH   = os.path.join(LOG_DIR,"AutoAdapt.log")
SECRET_PATH= os.path.join(BASE_DIR,"secrets","bridge_hmac.key")
CLOUD_URL  = "https://ariane.ngrok.io/bridge/sync"

def log(msg):
    os.makedirs(LOG_DIR, exist_ok=True)
    with open(LOG_PATH,"a",encoding="utf-8") as f:
        f.write(f"[{datetime.now()}] {msg}\n")

def sign_payload(payload: dict) -> str:
    try:
        with open(SECRET_PATH,"rb") as f:
            key=f.read().strip()
    except Exception: return ""
    data=json.dumps(payload,separators=(",",":")).encode("utf-8")
    return hmac.new(key,data,hashlib.sha256).hexdigest()

def send_report(payload):
    try:
        sig=sign_payload(payload)
        headers={"Content-Type":"application/json"}
        if sig: headers["X-HMAC-Signature"]=sig
        r=requests.post(CLOUD_URL,data=json.dumps(payload),headers=headers,timeout=10)
        log(f"☁️ Rapport envoyé : {r.status_code}")
    except Exception as e:
        log(f"⚠️ Erreur envoi cloud: {e}")

def adjust_task_freq(task, minutes):
    try:
        cmd=f'schtasks /change /tn "{task}" /sc minute /mo {minutes}'
        subprocess.run(cmd, shell=True, capture_output=True)
        log(f"🔁 Fréquence ajustée: {task} -> {minutes} min")
    except Exception as e:
        log(f"[ERREUR] Ajustement tâche {task}: {e}")

def adjust_process_priority(name, level):
    try:
        for proc in psutil.process_iter(["name"]):
            if name.lower() in proc.info["name"].lower():
                proc.nice(level)
                log(f"⚙️ Priorité ajustée: {name} -> {level}")
    except Exception as e:
        log(f"[ERREUR] Priorité {name}: {e}")

def apply_adaptations():
    if not os.path.exists(PLAN_PATH):
        log("[WARN] Aucun plan trouvé.")
        return

    with open(PLAN_PATH,"r",encoding="utf-8") as f:
        plan=json.load(f)

    cpu,ram,actions = plan.get("avg_cpu",0), plan.get("avg_ram",0), plan.get("actions",[])
    log(f"Analyse: CPU={cpu}%, RAM={ram}%, Actions={actions}")

    # Ajustement priorités selon charge
    if cpu>85 or ram>85:
        adjust_process_priority("python", psutil.BELOW_NORMAL_PRIORITY_CLASS)
        adjust_task_freq("Ariane_AutoHarmony", 10)
        adjust_task_freq("Ariane_AutoLearning", 15)
    elif cpu<60 and ram<60:
        adjust_process_priority("python", psutil.HIGH_PRIORITY_CLASS)
        adjust_task_freq("Ariane_AutoHarmony", 3)
        adjust_task_freq("Ariane_AutoLearning", 5)
    else:
        adjust_process_priority("python", psutil.NORMAL_PRIORITY_CLASS)

    report={
        "timestamp": datetime.now().isoformat(),
        "avg_cpu": cpu,
        "avg_ram": ram,
        "applied_actions": actions,
        "result": "Adaptation applied"
    }
    send_report(report)

if __name__=="__main__":
    log("=== DÉMARRAGE AUTO_ADAPT ===")
    apply_adaptations()
    log("=== FIN AUTO_ADAPT ===")
