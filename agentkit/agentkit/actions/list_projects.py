import os, json
ROOT = r"C:\\Ariane-Agent\\Projects"
def run(payload=None):
    if not os.path.exists(ROOT): return {"projects":[]}
    projs=[]
    for p in os.listdir(ROOT):
        path=os.path.join(ROOT,p)
        meta=os.path.join(path,"meta.json")
        if os.path.exists(meta):
            with open(meta,"r",encoding="utf-8") as f: data=json.load(f)
            data["path"]=path; projs.append(data)
    return {"projects":projs}
if __name__=="__main__": print(run())
