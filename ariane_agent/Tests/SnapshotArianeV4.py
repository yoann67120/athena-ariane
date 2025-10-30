# ====================================================================
# 📦 Ariane V4 - Snapshot Backup (Phase 7.4)
# Auteur : Yoann Rousselle
# ====================================================================

import os
import shutil
import datetime
import zipfile
import sys
sys.stdout.reconfigure(encoding='utf-8')

# === CONFIGURATION ===
SOURCE_DIR = r"C:\Users\Sonia\Dropbox\ArianeV4"   # répertoire d’Athena
BACKUP_ROOT = r"C:\Ariane-Agent\Backups\ArianeV4_Snapshots"
LOG_FILE = r"C:\Ariane-Agent\logs\Snapshot.log"

# === OUTILS DE LOG ===
def log(msg):
    ts = datetime.datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"{ts} {msg}\n")
    print(msg)

# === SNAPSHOT ===
def create_snapshot():
    os.makedirs(BACKUP_ROOT, exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    zip_name = f"ArianeV4_Snapshot_{ts}.zip"
    zip_path = os.path.join(BACKUP_ROOT, zip_name)

    log(f"=== Création du snapshot {zip_name} ===")

    try:
        with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for root, _, files in os.walk(SOURCE_DIR):
                for file in files:
                    path = os.path.join(root, file)
                    rel = os.path.relpath(path, os.path.dirname(SOURCE_DIR))
                    try:
                        archive.write(path, rel)
                    except Exception as e:
                        log(f"⚠️ Fichier ignoré : {path} ({e})")
        size = os.path.getsize(zip_path) / (1024 * 1024)
        log(f"✅ Snapshot terminé ({size:.2f} Mo) → {zip_path}")
        return zip_path
    except Exception as e:
        log(f"❌ Erreur lors du snapshot : {e}")
        return None

if __name__ == "__main__":
    log("=== DÉBUT SNAPSHOT ARIANE V4 ===")
    result = create_snapshot()
    if result:
        log(f"=== FIN SNAPSHOT : {result} ===")
    else:
        log("⚠️ Snapshot non créé.")
