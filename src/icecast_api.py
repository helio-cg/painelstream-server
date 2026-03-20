from flask import Flask, jsonify, request
import requests

app = Flask(__name__)

ICECAST_URL = "http://127.0.0.1:8000/status-json.xsl"
TOKEN = "segredo123"

@app.route("/radio/<mount>")
def radio_stats(mount):

    # 🔒 Verificação do token
    token = request.args.get("token")
    if token != TOKEN:
        return jsonify({"error": "Não autorizado"}), 403

    try:
        r = requests.get(ICECAST_URL, timeout=5)
        data = r.json()

        sources = data.get("icestats", {}).get("source", [])
        if isinstance(sources, dict):
            sources = [sources]

        for s in sources:
            if s.get("listenurl", "").endswith(mount):
                return jsonify({
                    "mount": mount,
                    "listeners": s.get("listeners", 0),
                    "title": s.get("title", ""),
                    "bitrate": s.get("bitrate", 0)
                })

        return jsonify({"error": "Mount não encontrado"}), 404

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)