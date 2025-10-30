# ====================================================================
# 🚗 COCKPIT ATHENA – UNIFIED SERVER v4.0
# Visual + Vocal + Usine Sync
# ====================================================================

from flask import Flask, render_template, jsonify, request
import os, datetime, psutil, socket, requests, threading, time
import pyttsx3
from playsound import playsound

# === CONFIGURATION ===
BASE_DIR = r"C:\Ariane-Agent\CockpitAthena"
LOG_FILE = r"C:\Ariane-Agent\logs\CockpitAthenaUnified.log"
USINE_URL = "http://localhost:5050/list"
SOUNDS = os.path.join(BASE_DIR, "static", "sounds")

app = Flask(__name__, template_folder="templates", static_folder="static")

os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
engine = pyttsx3.init()

# === OUTILS ===
def log(msg: str):
    ts = datetime.datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")
    line = f"{ts} {msg}"
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")
    print(line)

def play(sound):
    """Lecture d’un son WAV"""
    path = os.path.join(SOUNDS, sound)
    if os.path.exists(path):
        threading.Thread(target=lambda: playsound(path), daemon=True).start()

def speak_text(text):
    """Synthèse vocale asynchrone"""
    def run_tts():
        try:
            log(f"[TTS] Athena dit : {text}")
            engine.say(text)
            engine.runAndWait()
        except Exception as e:
            log(f"❌ Erreur TTS : {e}")
    threading.Thread(target=run_tts, daemon=True).start()

# === ROUTES VISUELLES ===
@app.route("/")
def home():
    log("🧠 Accès Cockpit Athena K2000")
    play("online.wav")
    return render_template("index.html")

@app.route("/status")
def status():
    """Statut système temps réel"""
    try:
        cpu = psutil.cpu_percent(interval=0.3)
        ram = psutil.virtual_memory().percent
        try:
            socket.create_connection(("8.8.8.8", 53), timeout=1)
            net = "OK"
        except OSError:
            net = "OFFLINE"
        state = "Stable" if cpu < 75 else "High Load"
        return jsonify({"cpu": cpu, "ram": ram, "network": net, "state": state})
    except Exception as e:
        log(f"❌ /status : {e}")
        return jsonify({"error": str(e)})

@app.route("/mode/<string:mode>")
def mode(mode):
    log(f"🛠️ Mode → {mode.upper()}")
    play("mode.wav")
    speak_text(f"Mode {mode} activé.")
    return jsonify({"mode": mode.upper(), "status": "ok"})

@app.route("/projects")
def projects():
    """Synchronisation avec l’Usine à Projets"""
    try:
        r = requests.get(USINE_URL, timeout=3)
        data = r.json()
        n = len(data.get("result", []))
        log(f"🔗 Sync Usine : {n} projet(s)")
        speak_text(f"Synchronisation de l'usine terminée, {n} projet(s) détecté(s).")
        return jsonify(data)
    except Exception as e:
        log(f"⚠️ Erreur Usine : {e}")
        play("alert.wav")
        speak_text("Erreur de communication avec l'usine.")
        return jsonify({"error": str(e)})

# === ROUTES VOCALES ===
@app.route("/health", methods=["GET"])
def health():
    """Santé du module vocal"""
    log("[HEALTH] AthenaVoice opérationnel.")
    return jsonify({"status": "ok", "module": "AthenaVoice", "time": datetime.datetime.now().isoformat()})

@app.route("/speak", methods=["POST"])
def speak():
    """Reçoit un texte et le prononce"""
    data = request.get_json(force=True)
    text = data.get("text", "")
    if not text:
        return jsonify({"error": "Aucun texte reçu"}), 400
    log(f"[TTS] Reçu : {text}")
    speak_text(text)
    return jsonify({"status": "speaking", "text": text})

# === LANCEMENT MULTI-THREAD ===
def run_flask(port):
    app.run(host="0.0.0.0", port=port, debug=False, use_reloader=False)

if __name__ == "__main__":
    log("=== Démarrage Cockpit Athena UNIFIED v4.0 ===")
    play("online.wav")
    speak_text("Athena, cockpit et système vocal opérationnels.")
    threading.Thread(target=lambda: run_flask(5070), daemon=True).start()  # TTS API
    run_flask(8080)  # Cockpit principal
