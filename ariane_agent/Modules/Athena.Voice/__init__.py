from Athena.TTS import speak
from Athena.STT import listen_once
import threading, time

def start_voice_loop():
    while True:
        cmd = listen_once()
        if cmd and "athena" in cmd.lower():
            speak("Oui, je vous écoute.")
