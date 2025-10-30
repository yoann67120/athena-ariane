import os, subprocess, datetime, psutil, time, json, requests

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")
with open(CONFIG_PATH, "r", encoding="utf-8") as f:
    CONFIG = json.load(f)
LOG_FILE = CONFIG["log_path"]

def log(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[SelfMaintenance] [{ts}] {msg}\n")

def check_process_running(keyword):
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            if any(keyword.lower() in str(p).lower() for p in proc.info['cmdline']):
                return True
        except Exception:
            continue
    return False

def restart_voice():
    ps_script = os.path.join("C:\\Ariane-Agent", "Start-AthenaVoice.ps1")
    subprocess.Popen(["powershell", "-ExecutionPolicy", "Bypass", ps_script])
    log("Redémarrage vocal lancé.")

def self_check():
    try:
        r = requests.get(f"http://localhost:{CONFIG['server_port']}/", timeout=2)
        if r.status_code == 200:
            log("Serveur vocal actif ✅")
            return
    except Exception:
        pass
    log("⚠️ Serveur vocal inactif, redémarrage...")
    restart_voice()

if __name__ == "__main__":
    if not check_process_running("Athena.VoiceLink"):
        log("Process Flask non trouvé, redémarrage nécessaire.")
        restart_voice()
    else:
        log("Process détecté, vérification HTTP...")
        self_check()
