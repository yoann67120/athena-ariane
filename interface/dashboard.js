
// ============================================================================
// 🧠 Athena Cockpit Dashboard.js
// Version : v4.0 – LiveLink (Socket Integration)
// ============================================================================

console.log("🛰️ Chargement du Dashboard Athena...");

const wsPort = 9091; // Port WebSocket actif côté SocketServer
let ws;

// Sélecteurs d’éléments visuels
const statusZone = document.getElementById("statusLog") || createStatusZone();
const barVoice = document.getElementById("bar-voice");
const barAthena = document.getElementById("bar-athena");

// Création dynamique de la zone de log si elle n’existe pas
function createStatusZone() {
  const div = document.createElement("div");
  div.id = "statusLog";
  div.style.cssText = `
    position:absolute;
    bottom:10px;
    left:10px;
    width:95%;
    height:30%;
    overflow-y:auto;
    font-family:Consolas, monospace;
    font-size:14px;
    background:rgba(0,0,0,0.4);
    color:#0ff;
    padding:10px;
    border-radius:10px;
  `;
  document.body.appendChild(div);
  return div;
}

// ============================================================================
// 🔌 Connexion WebSocket
// ============================================================================
function connectWebSocket() {
  ws = new WebSocket(`ws://localhost:${wsPort}`);
  ws.onopen = () => {
    addLog("🌐 Connexion établie avec Athena (port " + wsPort + ")", "system");
    ws.send("hello from Cockpit");
  };
  ws.onmessage = (event) => handleSocketMessage(event.data);
  ws.onerror = (err) => {
  console.error("Erreur WebSocket détectée :", err);
  addLog("⚠️ Erreur WebSocket : connexion refusée ou bloquée", "error");
};

  ws.onclose = () => {
    addLog("🔌 Déconnexion WebSocket, reconnexion dans 5s...", "warning");
    setTimeout(connectWebSocket, 5000);
  };
}

// ============================================================================
// 🧠 Gestion des messages reçus
// ============================================================================
function handleSocketMessage(message) {
  addLog(message);

  // Animation & couleur selon le type
  if (message.includes("❌") || message.includes("[error]")) {
    flashCockpit("red");
    speak("Erreur détectée dans le système Athena");
  } else if (message.includes("⚠️") || message.includes("[warning]")) {
    flashCockpit("orange");
  } else if (message.includes("✅") || message.includes("[success]")) {
    flashCockpit("lime");
    speak("Cycle terminé avec succès");
  } else if (message.includes("🧠") || message.includes("[info]")) {
    flashCockpit("cyan");
  }

  // Scroll automatique
  statusZone.scrollTop = statusZone.scrollHeight;
}

// ============================================================================
// 💬 Fonctions utilitaires
// ============================================================================
function addLog(msg, type = "info") {
  const p = document.createElement("p");
  p.textContent = msg;
  const color = {
    info: "#0ff",
    success: "#0f0",
    warning: "#ff0",
    error: "#f44",
    system: "#0af"
  }[type] || "#0ff";
  p.style.color = color;
  statusZone.appendChild(p);
}

function flashCockpit(color) {
  document.body.style.transition = "background 0.3s ease";
  document.body.style.background = color;
  setTimeout(() => (document.body.style.background = "black"), 500);
}

// ============================================================================
// 🔊 Synthèse vocale (navigateur)
// ============================================================================
function speak(text) {
  if (!window.speechSynthesis) return;
  const utter = new SpeechSynthesisUtterance(text);
  utter.lang = "fr-FR";
  utter.pitch = 1;
  utter.rate = 1;
  utter.volume = 1;
  speechSynthesis.speak(utter);
}

// ============================================================================
// 🧭 Commandes interactives (préparation futur)
// ============================================================================
window.sendCommand = function (cmd) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send("invoke:" + cmd);
    addLog("🛰️ Commande envoyée à Athena : " + cmd, "system");
  } else {
    addLog("❌ Connexion WebSocket non disponible.", "error");
  }
};
// ============================================================================
// 🎮 Gestion des boutons interactifs P0 à P7
// ============================================================================

const buttons = [
  { id: "btnP0", cmd: "Invoke-AthenaMasterCycle", desc: "Cycle complet" },
  { id: "btnP1", cmd: "Invoke-AthenaAutoLearning", desc: "Auto-Learning" },
  { id: "btnP2", cmd: "Invoke-AthenaAutoRepair", desc: "Auto-Repair" },
  { id: "btnP3", cmd: "Invoke-AthenaAutoHarmony", desc: "Auto-Harmony" },
  { id: "btnP4", cmd: "Invoke-AthenaAutoOptimization", desc: "Auto-Optimize" },
  { id: "btnP5", cmd: "Invoke-AthenaAutoSign", desc: "Signature/Validation" },
  { id: "btnP6", cmd: "Invoke-AthenaDashboardReport", desc: "Rapport visuel" },
  { id: "btnP7", cmd: "Restart-CockpitSocketServer", desc: "Redémarrage Socket" },
];

buttons.forEach(b => {
  const el = document.getElementById(b.id);
  if (!el) return;
  el.addEventListener("click", () => {
    sendCommand(b.cmd);
    flashCockpit("blue");
    speak("Commande " + b.desc + " envoyée à Athena.");
  });
});

// ============================================================================
// 🏁 Démarrage
// ============================================================================
window.addEventListener("load", () => {
  addLog("🚀 Initialisation du Cockpit...");
  connectWebSocket();
});
