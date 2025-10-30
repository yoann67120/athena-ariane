/* ============================================================
   Athena Cockpit – Soft Light Edition
   Script principal
   ============================================================ */

/* --- paramètres utilisateur --- */
let prefs = {
  mode: "AUTO",
  volume: 0.7,
  scannerSound: true,
  theme: "K2000",
  refreshRate: 1000
};

const prefsFile = "user_prefs.json";

/* --- récupération des éléments de l'interface --- */
const bars = [document.getElementById("bar1"),
              document.getElementById("bar2"),
              document.getElementById("bar3")];
const halo = document.getElementById("emotion-halo");
const indicators = {
  cpu: document.getElementById("cpu"),
  ram: document.getElementById("ram"),
  net: document.getElementById("net"),
  mood: document.getElementById("mood")
};
const chatHistory = document.getElementById("chat-history");
const userInput = document.getElementById("user-input");
const sendBtn = document.getElementById("send-btn");
const micBtn = document.getElementById("mic-btn");
const scannerSound = document.getElementById("scannerSound");
const notifications = document.getElementById("notifications");
const failsafe = document.getElementById("failsafe");

/* --- utilitaires --- */
function notify(msg) {
  const n = document.createElement("div");
  n.className = "notification";
  n.textContent = msg;
  notifications.appendChild(n);
  setTimeout(() => n.remove(), 6000);
}

/* --- simulation mode démo --- */
let demoMode = true;
let demoPhase = 0;
function demoTick() {
  demoPhase = (demoPhase + 1) % 360;
  const hue = Math.abs(Math.sin(demoPhase * Math.PI / 180));
  halo.style.background = `radial-gradient(circle, rgba(${Math.floor(255*hue)},0,0,0.3), transparent 70%)`;
  bars.forEach(b => b.style.background = `linear-gradient(to top, rgba(${255*hue},0,0,0.9), rgba(50,0,0,0.3))`);
  if (demoPhase % 120 === 0) notify("Athena est en veille cognitive…");
}

/* --- lecture des fichiers d’état --- */
async function updateFromFiles() {
  try {
    const [emotion, harmony, status] = await Promise.all([
      fetch("../Memory/EmotionState.json").then(r => r.json()).catch(()=>null),
      fetch("../Memory/HarmonyState.json").then(r => r.json()).catch(()=>null),
      fetch("../Memory/StatusBridge.json").then(r => r.json()).catch(()=>null)
    ]);
    if (!emotion && !harmony && !status) { demoMode = true; return; }
    demoMode = false;

    const moodColor = emotion?.Color || harmony?.Color || "#ff0000";
    halo.style.background = `radial-gradient(circle, ${moodColor}33, transparent 70%)`;

    indicators.cpu.style.background = status?.CPUColor || "#ff4444";
    indicators.ram.style.background = status?.RAMColor || "#ff4444";
    indicators.net.style.background = status?.NetColor || "#ff4444";
    indicators.mood.style.background = moodColor;
  } catch (e) {
    console.warn("Erreur lecture fichiers :", e);
  }
}

/* --- animation scanner --- */
function animateScanner() {
  bars.forEach((bar, i) => {
    bar.style.animationDelay = `${i * 0.3}s`;
  });
}

/* --- chat interactif --- */
function addMessage(sender, text) {
  const div = document.createElement("div");
  div.className = sender === "user" ? "user" : "athena";
  div.textContent = `${sender === "user" ? "Toi" : "Athena"} : ${text}`;
  chatHistory.appendChild(div);
  chatHistory.scrollTop = chatHistory.scrollHeight;
}

/* --- envoi message au backend --- */
async function sendMessage() {
  const text = userInput.value.trim();
  if (!text) return;
  addMessage("user", text);
  userInput.value = "";

  try {
    // Écriture du message pour Athena (fallback JSON)
    const payload = {
      source: "User",
      message: text,
      timestamp: new Date().toISOString()
    };
    await fetch("last_message.json", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    notify("Message envoyé à Athena.");
  } catch (e) {
    console.warn("Impossible d’envoyer le message :", e);
  }
}

/* --- boutons chat --- */
sendBtn.addEventListener("click", sendMessage);
userInput.addEventListener("keydown", e => { if (e.key === "Enter") sendMessage(); });

/* --- initialisation --- */
function init() {
  animateScanner();
  if (prefs.scannerSound) {
    scannerSound.volume = prefs.volume;
    scannerSound.play().catch(()=>{});
  }
  notify("Cockpit Athena initialisé.");
  setInterval(() => {
    if (demoMode) demoTick();
    else updateFromFiles();
  }, prefs.refreshRate);
}

/* --- mode secours --- */
window.addEventListener("error", e => {
  console.error("Erreur détectée :", e);
  failsafe.classList.remove("hidden");
});

document.getElementById("reload-main").addEventListener("click", () => {
  failsafe.classList.add("hidden");
  location.reload();
});

/* --- démarrage --- */
window.onload = init;
/* ============================================================
   Connexion WebSocket avec Athena via le Cockpit (auto-détection)
   ============================================================ */
let ws;
let triedPorts = [9191, 9192]; // ports possibles (HTTP proxy / direct WebSocket)
let currentPortIndex = 0;

function connectSocket() {
  if (currentPortIndex >= triedPorts.length) {
    notify("❌ Impossible de se connecter à Athena (tous les ports ont échoué).");
    console.warn("Aucune connexion possible.");
    return;
  }

  let port = triedPorts[currentPortIndex];
  let url = `ws://127.0.0.1:${port}`;
  console.log(`Tentative de connexion WebSocket : ${url}`);

  try {
    ws = new WebSocket(url);

    ws.onopen = () => {
      notify(`🧠 Lien établi avec Athena (port ${port}).`);
document.body.classList.add("connected");

      console.log(`✅ WebSocket connecté sur ${url}`);
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.message) addMessage("athena", data.message);
      } catch (e) {
        console.warn("Erreur traitement message :", e, event.data);
      }
    };

    ws.onclose = () => {
      console.warn(`Connexion perdue sur le port ${port}.`);
      currentPortIndex++;
      setTimeout(connectSocket, 3000); // essaie le port suivant
    };

    ws.onerror = (err) => {
      console.error(`Erreur WebSocket sur ${port}:`, err);
      ws.close();
    };
  } catch (err) {
    console.error("Erreur fatale WebSocket :", err);
  }
}

/* --- redéfinition de l’envoi de message pour passer par le socket --- */
async function sendMessage() {
  const text = userInput.value.trim();
  if (!text) return;
  addMessage("user", text);
  userInput.value = "";
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ source: "User", message: text }));
  } else {
    notify("Socket non connecté ; message enregistré localement.");
  }
}

/* --- connexion automatique au chargement --- */
window.addEventListener("load", connectSocket);
