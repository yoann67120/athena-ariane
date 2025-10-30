# ====================================================================
# 🧾 Ariane V4 - Fusion et Standardisation des Logs
# Phase 7.2 - One Shot
# Auteur : Yoann Rousselle
# ====================================================================

import os
import re
import datetime

LOG_DIR = r"C:\Ariane-Agent\logs"
OUTPUT_FILE = os.path.join(LOG_DIR, "Global.log")
BACKUP_FILE = os.path.join(LOG_DIR, f"Global_{datetime.datetime.now():%Y%m%d_%H%M%S}.log")

# --- Étape 1 : collecter tous les fichiers .log ---
log_files = [os.path.join(LOG_DIR, f) for f in os.listdir(LOG_DIR) if f.lower().endswith(".log")]

if not log_files:
    print("❌ Aucun fichier .log trouvé.")
    exit()

entries = []

def normalize_line(line, filename):
    """Nettoie et identifie le module à partir du nom du fichier"""
    base = os.path.basename(filename).replace(".log", "").upper()
    base = re.sub(r"[^A-Z0-9]", "", base)
    ts_match = re.search(r"\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]", line)
    if ts_match:
        ts_str = ts_match.group(1)
    else:
        ts_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    msg = re.sub(r"^\[.*?\]\s*", "", line.strip())
    return f"[{ts_str}] [{base}] {msg}", ts_str

# --- Étape 2 : lire chaque log ---
for file in log_files:
    try:
        with open(file, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if line.strip():
                    norm, ts = normalize_line(line, file)
                    try:
                        dt = datetime.datetime.strptime(ts, "%Y-%m-%d %H:%M:%S")
                    except Exception:
                        dt = datetime.datetime.now()
                    entries.append((dt, norm))
    except Exception as e:
        print(f"⚠️ Erreur lecture {file}: {e}")

# --- Étape 3 : trier chronologiquement ---
entries.sort(key=lambda x: x[0])

# --- Étape 4 : sauvegarde et fusion ---
os.makedirs(LOG_DIR, exist_ok=True)
with open(BACKUP_FILE, "w", encoding="utf-8") as f:
    for _, line in entries:
        f.write(line + "\n")

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    for _, line in entries:
        f.write(line + "\n")

print(f"✅ Fusion terminée : {len(entries)} lignes consolidées.")
print(f"📁 Fichier principal : {OUTPUT_FILE}")
print(f"🗄️ Sauvegarde créée : {BACKUP_FILE}")
