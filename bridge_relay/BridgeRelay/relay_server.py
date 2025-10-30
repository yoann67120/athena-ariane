from flask import Flask, request, jsonify
import requests, json, os

app = Flask(__name__)

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "relay_config.json")
with open(CONFIG_PATH, "r", encoding="utf-8") as f:
    CONFIG = json.load(f)

LOCAL_BRIDGE = CONFIG.get("local_bridge", "http://localhost:5075")
AUTH_KEY = CONFIG.get("auth_key", "ARIANE_RELAY_KEY")

@app.route("/")
def root():
    return jsonify({
        "status": "🟢 BridgeRelay opérationnel",
        "forward_to": LOCAL_BRIDGE
    })

@app.route("/bridge/<path:endpoint>", methods=["POST", "GET"])
def bridge_proxy(endpoint):
    try:
        headers = {"X-Relay-Key": AUTH_KEY}
        if request.method == "POST":
            resp = requests.post(f"{LOCAL_BRIDGE}/{endpoint}", json=request.json, headers=headers, timeout=10)
        else:
            resp = requests.get(f"{LOCAL_BRIDGE}/{endpoint}", headers=headers, timeout=10)
        return (resp.text, resp.status_code, resp.headers.items())
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
