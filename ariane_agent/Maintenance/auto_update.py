import os, subprocess, time, datetime

LOG = r"C:\Ariane-Agent\logs\AutoMaintenance.log"
def log(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.datetime.now()}] [auto_update] {msg}\n")

def run(cmd):
    log(f"Exécution : {cmd}")
    subprocess.run(cmd, shell=True)

def main():
    log("=== DÉMARRAGE AUTO_UPDATE ===")
    while True:
        try:
            run("powershell -ExecutionPolicy Bypass -File C:\\Ariane-Agent\\Scripts\\Update-System.ps1")
            log("✅ Système vérifié et mis à jour")
        except Exception as e:
            log(f"❌ Erreur update : {e}")
        time.sleep(3600)  # Vérifie toutes les heures

if __name__ == "__main__":
    main()
