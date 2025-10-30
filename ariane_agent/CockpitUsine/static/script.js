// ------------------------- PROJETS -------------------------
async function loadProjects() {
  const list = document.getElementById("project-list");
  list.textContent = "Chargement...";
  try {
    const res = await fetch("/projects");
    const data = await res.json();
    list.innerHTML = "";
    if (data.length === 0) {
      list.textContent = "Aucun projet trouvé.";
      return;
    }
    data.forEach(p => {
      const card = document.createElement("div");
      card.className = "project-card";
      const name = p.Nom || p.name;
      card.innerHTML = `
        <h3>${name}</h3>
        <p><b>Type :</b> ${p.Type || "?"}</p>
        <p><b>État :</b> ${p.Etat || "?"}</p>
        <button onclick="deployProject('${name}')">🚀 Déployer</button>
        <button onclick="deleteProject('${name}')">🗑️ Supprimer</button>
      `;
      list.appendChild(card);
    });
  } catch (e) {
    list.textContent = "❌ Erreur de chargement.";
    console.error(e);
  }
}

async function createProject() {
  const name = document.getElementById("project-name").value.trim();
  const type = document.getElementById("project-type").value;
  if (!name) return alert("Nom requis.");
  const res = await fetch("/create", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name, type })
  });
  await res.json();
  alert("✅ Projet créé : " + name);
  loadProjects();
}

async function deployProject(name) {
  const res = await fetch("/deploy", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name })
  });
  await res.json();
  alert("🚀 Déploiement de " + name);
}

async function deleteProject(name) {
  if (!confirm("Supprimer " + name + " ?")) return;
  const res = await fetch("/delete", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name })
  });
  await res.json();
  alert("🗑️ Projet supprimé : " + name);
  loadProjects();
}

// --------------------------- LOGS ---------------------------
async function loadLogs() {
  try {
    const res = await fetch("/logs");
    const data = await res.json();
    const box = document.getElementById("log-box");
    box.textContent = data.lines.join("");
    box.scrollTop = box.scrollHeight;
  } catch (e) { console.error(e); }
}

// --------------------------- BOUTONS ---------------------------
document.getElementById("btn-refresh").addEventListener("click", loadProjects);
document.getElementById("btn-create").addEventListener("click", createProject);
document.getElementById("btn-athena").addEventListener("click", async () => {
  const res = await fetch("/open-athena");
  const data = await res.json();
  alert(data.message);
});

// --------------------------- INIT ---------------------------
window.onload = () => {
  loadProjects();
  loadLogs();
  setInterval(loadLogs, 5000);
};
