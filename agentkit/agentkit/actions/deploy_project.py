import os, subprocess, datetime
def run(payload=None):
    project = payload.get("project")
    if not project or not os.path.exists(project):
        return {"error":"Projet introuvable"}
    ps1 = os.path.join(project,"Scripts","Start-Athena.ps1")
    if not os.path.exists(ps1):
        return {"error":"Script Start-Athena.ps1 absent"}
    subprocess.run(["powershell","-ExecutionPolicy","Bypass","-File",ps1])
    return {"status":"deployed","timestamp":datetime.datetime.now().isoformat()}
if __name__=="__main__":
    print(run({"project":r"C:\\Ariane-Agent\\UsineAProjets\\templates\\AthenaV4"}))
