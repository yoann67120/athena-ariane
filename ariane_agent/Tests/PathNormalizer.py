# ====================================================================
# 🧹 Ariane V4 - Path Normalizer (Phase 7.3)
# Auteur : Yoann Rousselle
# ====================================================================

import os, re, datetime

# --- CONFIG ---
ROOT = r"C:\Users"
TARGET_DIR = r"C:\Users"
LOG_FILE = r"C:\Ariane-Agent\logs\PathNormalizer.log"
PATTERNS = [
    r"C:\\Users\\[A-Za-z0-9_-]+\\Dropbox\\ArianeV4",
    r"[A-Z]:\\\\Users\\\\[A-Za-z0-9_-]+\\\\Dropbox\\\\ArianeV4"
]
REPLACEMENT = "$env:ARIANE_ROOT"

# --- LOG ---
def log(msg):
    ts = datetime.datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"{ts} {msg}\n")
    print(msg)

# --- SCAN ---
def normalize_paths(base_dir):
    count, fixed = 0, 0
    for root, _, files in os.walk(base_dir):
        for file in files:
            if file.lower().endswith((".psm1", ".ps1")):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                    original = content
                    for p in PATTERNS:
                        content = re.sub(p, REPLACEMENT, content, flags=re.IGNORECASE)
                    if content != original:
                        with open(path, "w", encoding="utf-8") as f:
                            f.write(content)
                        log(f"🧩 Corrigé : {path}")
                        fixed += 1
                    count += 1
                except Exception as e:
                    log(f"⚠️ Erreur sur {path}: {e}")
    log(f"✅ Terminé : {fixed}/{count} fichiers corrigés.")
    return fixed, count

if __name__ == "__main__":
    log("=== DÉBUT DE LA NORMALISATION DES CHEMINS ===")
    fixed, count = normalize_paths(TARGET_DIR)
    log(f"=== FIN DE LA NORMALISATION : {fixed}/{count} fichiers corrigés ===")
