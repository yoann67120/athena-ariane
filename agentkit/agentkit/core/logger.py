# -*- coding: utf-8 -*-
import os, datetime
LOG_DIR  = r"C:\Ariane-Agent\logs"
LOG_FILE = os.path.join(LOG_DIR,"agentkit.log")
os.makedirs(LOG_DIR, exist_ok=True)
def log(msg:str):
    ts   = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    with open(LOG_FILE,"a",encoding="utf-8") as f: f.write(line+"\n")
    print(line)
