import subprocess
import json
import sys
from datetime import datetime
import geoip2.database
import requests
import warnings
from urllib3.exceptions import InsecureRequestWarning

# Caminho do banco GeoIP2
GEOIP_DB_PATH = '/var/www/src/modulos/estatisticas/GeoLite2-City.mmdb'

# Ignora avisos de HTTPS não verificado
warnings.simplefilter('ignore', InsecureRequestWarning)

# --- Funções auxiliares ---
def get_browser(ip):
    return "Desconhecido"

def get_tempo(ip):
    return datetime.now().isoformat()

def get_users_on_port(port):
    """
    Retorna lista de ouvintes conectados na porta com geo-localização
    """
   # cmd = f"netstat -anp | grep :{port} | grep ESTABLISHED"
    cmd = f"netstat -anp | grep ESTABLISHED | grep -E '(:{port}|:{port2})'"

    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    ips = set()
    for line in result.stdout.strip().split("\n"):
        if line:
            ip_port = line.split()[4]
            ip = ip_port.split(":")[0]
            if ip != "127.0.0.1":
                ips.add(ip)

    reader = geoip2.database.Reader(GEOIP_DB_PATH)
    data = []

    for ip in ips:
        try:
            response = reader.city(ip)
            location = {
                'country': response.country.name,
                'countryCode': response.country.iso_code.lower(),
                'region': response.subdivisions.most_specific.name,
                'city': response.city.name,
                'latitude': response.location.latitude,
                'longitude': response.location.longitude
            }
        except Exception:
            location = {}

        data.append({
            'ip': ip,
            'country': location.get('country', 'Desconhecido'),
            'countryCode': location.get('countryCode', 'unknown'),
            'region': location.get('region', 'Desconhecido'),
            'city': location.get('city', 'Desconhecido'),
            'latitude': location.get('latitude'),
            'longitude': location.get('longitude')
        })

    reader.close()
    return data

# --- Funções para Icecast / Shoutcast ---
def get_icecast_stats(port):
    ICECAST_URL = f"https://localhost:{port}/status-json.xsl"
    try:
        resp = requests.get(ICECAST_URL, verify=False, timeout=5)
        resp.raise_for_status()
        data = resp.json()
        sources = data.get('icestats', {}).get('source', [])
        if isinstance(sources, dict):
            sources = [sources]

        result = []
        for source in sources:
            result.append({
                'tipo': 'Icecast',
                'stream': source.get('listenurl', 'Desconhecido'),
                'ouvintes_online': source.get('listeners', 0),
                'pico_ouvintes': source.get('listener_peak', 0),
                'limite': source.get('listener_limit', 0),
                'listeners': get_users_on_port(port)
            })
        return result
    except (requests.exceptions.RequestException, ValueError):
        return []

def get_shoutcast_stats(port):
    SHOUTCAST_URL = f"https://localhost:{port}/stats?sid=1&json=1"
    try:
        resp = requests.get(SHOUTCAST_URL, verify=False, timeout=5)
        resp.raise_for_status()
        data = resp.json()
        result = [{
            'tipo': 'Shoutcast',
            'stream': SHOUTCAST_URL,
            'ouvintes_online': data.get('uniquelisteners', 0),
            'pico_ouvintes': data.get('peaklisteners', 0),
            'limite': data.get('maxlisteners', 0),
            'listeners': get_users_on_port(port)
        }]
        return result
    except (requests.exceptions.RequestException, ValueError):
        return []

# --- Execução principal ---
if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Uso: python3 script.py <porta> <tipo: shoutcast|icecast> <port2>")
        sys.exit(1)

    porta_usuario = sys.argv[1]
    tipo = sys.argv[2].lower()
    port2 = sys.argv[3]

    if tipo == "shoutcast":
        stats = get_shoutcast_stats(porta_usuario)
    elif tipo == "icecast":
        stats = get_icecast_stats(porta_usuario)
    else:
        print("Tipo inválido! Use 'shoutcast' ou 'icecast'.")
        sys.exit(1)

    print(json.dumps(stats, indent=2, ensure_ascii=False))
