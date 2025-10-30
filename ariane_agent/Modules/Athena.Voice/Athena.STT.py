import speech_recognition as sr
import json, os, datetime

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")
with open(CONFIG_PATH, "r", encoding="utf-8") as f:
    CONFIG = json.load(f)
LOG_FILE = CONFIG["log_path"]

def log(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[STT] [{ts}] {msg}\n")

def listen_once():
    r = sr.Recognizer()
    with sr.Microphone() as source:
        log("Écoute en cours...")
        audio = r.listen(source)
    try:
        text = r.recognize_google(audio, language="fr-FR")
        log(f"Reconnu : {text}")
        return text
    except Exception as e:
        log(f"Erreur STT : {e}")
        return None

if __name__ == "__main__":
    print("🎤 Dites quelque chose...")
    result = listen_once()
    print("Vous avez dit :", result)
