import os, time, subprocess, datetime

LOG = r"C:\Ariane-Agent\logs\AutoMaintenance.log"
SERVICES = [
    ("Bridge", 5075, "C:\\Ariane-Agent\\Bridge\\bridge_server.py"),
    ("Usine", 5050, "C:\\Ariane-Agent\\UsineAProjets\\usine_server.py")
]

def log(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.datetime.now()}] [self_repair] {msg}\n")

def check_port(port):
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = s.connect_ex(("127.0.0.1", port))
    s.close()
    return result == 0

def main():
    log("=== DÉMARRAGE SELF_REPAIR ===")
    while True:
        for name, port, path in SERVICES:
            if not check_port(port):
                log(f"⚠️ {name} inactif sur port {port}, relance...")
                subprocess.Popen(["python", path], creationflags=subprocess.CREATE_NEW_CONSOLE)
                log(f"✅ {name} relancé.")
        time.sleep(180)  # Vérifie toutes les 3 minutes

if __name__ == "__main__":
    main()
