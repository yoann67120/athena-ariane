import os, shutil, datetime
TEMPLATE = r"C:\\Ariane-Agent\\UsineAProjets\\templates\\AthenaV4"
def run(payload=None):
    project = payload.get("project")
    if not project or not os.path.exists(project):
        return {"error":"Projet introuvable"}
    for root,dirs,files in os.walk(TEMPLATE):
        rel=os.path.relpath(root,TEMPLATE)
        target=os.path.join(project,rel)
        os.makedirs(target,exist_ok=True)
        for f in files:
            src=os.path.join(root,f); dst=os.path.join(target,f)
            shutil.copy2(src,dst)
    return {"status":"updated","timestamp":datetime.datetime.now().isoformat()}
if __name__=="__main__":
    print(run({"project":r"C:\\Ariane-Agent\\Projects\\Athena_Test"}))
