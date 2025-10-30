import os, json, datetime
TEMPLATE = r"C:\\Ariane-Agent\\UsineAProjets\\templates\\AthenaV4"
PROJECTS_DIR = r"C:\\Ariane-Agent\\Projects"
def run(payload=None):
    name = payload.get("name","AthenaV4_Clone_"+datetime.datetime.now().strftime("%H%M%S"))
    dest = os.path.join(PROJECTS_DIR, name)
    os.makedirs(dest, exist_ok=True)
    os.system(f"xcopy /E /I /Y \"{TEMPLATE}\" \"{dest}\" >nul")
    meta = os.path.join(dest, "meta.json")
    with open(meta,"r",encoding="utf-8") as f: data=json.load(f)
    data["deployed_at"]=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(meta,"w",encoding="utf-8") as f: json.dump(data,f,indent=2)
    return {"status":"created","project_path":dest}
if __name__=="__main__": print(run({"name":"Athena_Test"}))
