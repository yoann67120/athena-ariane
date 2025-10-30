from flask import Flask, request, jsonify
import requests, os, json, datetime
from Athena.TTS import speak

app = Flask(__name__)
CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")
with open(CONFIG_PATH, "r", encoding="utf-8") as f:
    CONFIG = json.load(f)
LOG_FILE = CONFIG["log_path"]

def log(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[VoiceLink] [{ts}] {msg}\n")

@app.route("/speak", methods=["POST"])
def api_speak():
    data = request.get_json(force=True)
    text = data.get("text", "")
    if not text:
        return jsonify({"error": "Missing text"}), 400
    speak(text)
    log(f"Said via API: {text}")
    return jsonify({"status": "ok", "spoken": text})

if __name__ == "__main__":
    log("VoiceLink démarré.")
    app.run(host="0.0.0.0", port=CONFIG["server_port"])
