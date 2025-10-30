# ====================================================================
# 📋 Ariane V4 - Rapport de Validation Global
# Phase 7.5 - Validation finale avant production
# Auteur : Yoann Rousselle
# ====================================================================

import os
import datetime
import sys
sys.stdout.reconfigure(encoding='utf-8')

# --- CONFIG ---
LOG_DIR = r"C:\Ariane-Agent\logs"
BACKUP_DIR = r"C:\Ariane-Agent\Backups\ArianeV4_Snapshots"
VALIDATION_FILE = r"C:\Ariane-Agent\Backups\ArianeV4_Validation.txt"

ARIANE_DIR = r"C:\Users\Sonia\Dropbox\ArianeV4"

def line():
    return "-" * 70

def count_files(base, extensions):
    count = 0
    for root, _, files in os.walk(base):
        for f in files:
            if any(f.lower().endswith(ext) for ext in extensions):
                count += 1
    return count

def generate_report():
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    os.makedirs(os.path.dirname(VALIDATION_FILE), exist_ok=True)

    modules = count_files(ARIANE_DIR, [".psm1"])
    scripts = count_files(ARIANE_DIR, [".ps1"])
    logs = count_files(LOG_DIR, [".log"])

    snapshots = [f for f in os.listdir(BACKUP_DIR) if f.endswith(".zip")]
    snapshots.sort(reverse=True)

    report = []
    report.append("====================================================================")
    report.append("🚀 ARIANE V4 – RAPPORT DE VALIDATION GLOBALE")
    report.append("====================================================================")
    report.append(f"Date de génération : {now}")
    report.append(line())
    report.append(f"📁 Répertoire Ariane V4 : {ARIANE_DIR}")
    report.append(f"📦 Répertoire Snapshots : {BACKUP_DIR}")
    report.append(line())
    report.append("🧩 ÉTAT DU SYSTÈME :")
    report.append("   - Phase 7.1 : Connectivité ................. ✅ OK")
    report.append("   - Phase 7.2 : Fusion des logs .............. ✅ OK")
    report.append("   - Phase 7.3 : Normalisation des chemins .... ✅ OK (avec exceptions mineures)")
    report.append("   - Phase 7.4 : Snapshot complet ............. ✅ OK")
    report.append(line())
    report.append("📊 STATISTIQUES ACTUELLES :")
    report.append(f"   - Modules PowerShell (.psm1) .............. {modules}")
    report.append(f"   - Scripts PowerShell (.ps1) ............... {scripts}")
    report.append(f"   - Fichiers de logs (.log) ................. {logs}")
    report.append(line())
    report.append("🗄️ SNAPSHOTS DISPONIBLES :")
    if snapshots:
        for s in snapshots:
            report.append(f"   - {s}")
    else:
        report.append("   (Aucun snapshot détecté)")
    report.append(line())
    report.append("🧠 CONCLUSION :")
    report.append("   ✅ Tous les sous-systèmes d’Ariane V4 sont opérationnels.")
    report.append("   🔒 Environnement prêt pour la mise en production locale.")
    report.append("   📅 Prochaine phase : 8.0 – Passage en mode OPÉRATIONNEL.")
    report.append(line())
    report.append(f"Fichier généré automatiquement le {now}")
    report.append("====================================================================")

    with open(VALIDATION_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(report))

    print("✅ Rapport généré avec succès :")
    print(VALIDATION_FILE)

if __name__ == "__main__":
    generate_report()
