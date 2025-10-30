async function refreshStatus() {
  try {
    const res = await fetch("/status");
    const d = await res.json();
    document.getElementById("cpu").textContent = d.cpu;
    document.getElementById("ram").textContent = d.ram;
    document.getElementById("net").textContent = d.network;
    document.getElementById("state").textContent = d.state;
  } catch(e){ console.error(e); }
}

async function refreshProjects() {
  try {
    const res = await fetch("/projects");
    const data = await res.json();
    const box = document.getElementById("projectList");
    if (data.result && data.result.length > 0) {
      box.innerHTML = data.result.map(
        p => `<div>• <b>${p.Nom}</b> – ${p.Type} (${p.Etat})</div>`
      ).join("");
    } else box.textContent = "Aucun projet trouvé.";
  } catch(e){
    document.getElementById("projectList").textContent = "⚠️ Usine injoignable.";
    console.error(e);
  }
}

async function setMode(mode) {
  const res = await fetch(`/mode/${mode}`);
  const data = await res.json();
  document.querySelectorAll("button").forEach(b => b.classList.remove("active"));
  document.getElementById(mode.toLowerCase()).classList.add("active");
  console.log("Mode :", data.mode);
}

setInterval(refreshStatus, 3000);
setInterval(refreshProjects, 5000);
refreshStatus(); refreshProjects();
