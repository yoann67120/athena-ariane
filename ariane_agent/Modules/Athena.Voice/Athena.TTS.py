import os, json, datetime
from gtts import gTTS
from playsound import playsound

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")
with open(CONFIG_PATH, "r", encoding="utf-8") as f:
    CONFIG = json.load(f)

LOG_FILE = CONFIG["log_path"]

def log(msg):
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[TTS] [{ts}] {msg}\n")

def speak(text, sound="confirm"):
    try:
        playsound(os.path.join(os.path.dirname(__file__), CONFIG["sounds"][sound]), False)
    except Exception:
        pass
    tts = gTTS(text=text, lang=CONFIG["language"])
    file = os.path.join(os.path.dirname(__file__), "tmp_tts.mp3")
    tts.save(file)
    playsound(file)
    os.remove(file)
    log(f"Athena said: {text}")

if __name__ == "__main__":
    log("Test vocal lancé.")
    speak("Bonjour, je suis Athena. Système vocal opérationnel.", "startup")
