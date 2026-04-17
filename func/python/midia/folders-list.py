import os
import json
import sys
import re

# ----------------------------
# CONFIG
# ----------------------------
BASE_TEMPLATE = "/home/{user}/ftp/pastas"

# pastas que serão ignoradas
IGNORE_DIRS = {'.git', '.cache', '.config', '__pycache__'}

# ----------------------------
# VALIDAR USER
# ----------------------------
if len(sys.argv) < 2:
    print(json.dumps({"error": "USER não informado"}))
    sys.exit(1)

USER = sys.argv[1]

if not re.match(r'^[a-z]{5,10}$', USER):
    print(json.dumps({"error": "USER inválido"}))
    sys.exit(1)

BASE_PATH = BASE_TEMPLATE.format(user=USER)

# ----------------------------
# VALIDAR CAMINHO
# ----------------------------
if not os.path.exists(BASE_PATH):
    print(json.dumps({"error": "Diretório não existe"}))
    sys.exit(1)

# ----------------------------
# SCAN
# ----------------------------
folders = []

for root, dirs, files in os.walk(BASE_PATH):
    # 🔥 ignora pastas indesejadas
    dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not d.startswith('.')]

    rel_path = os.path.relpath(root, BASE_PATH)

    if rel_path == ".":
        depth = 0
        path = ""
    else:
        depth = rel_path.count(os.sep) + 1
        path = rel_path

    mp3_count = 0
    total_size = 0
    last_modified = 0

    for file in files:
        if not file.lower().endswith('.mp3'):
            continue

        full_path = os.path.join(root, file)

        try:
            stat = os.stat(full_path)

            mp3_count += 1
            total_size += stat.st_size

            if stat.st_mtime > last_modified:
                last_modified = stat.st_mtime

        except Exception:
            continue

    # só salva pastas com mp3
    if mp3_count == 0:
        continue

    folders.append({
        "path": path,
        "name": os.path.basename(path) if path else "root",
        "depth": depth,
        "mp3_count": mp3_count,
        "total_size": total_size,
        "last_modified": int(last_modified),
        "sort_order": 0
    })

# ----------------------------
# ORDENAÇÃO
# ----------------------------
folders.sort(key=lambda x: x["path"])

# ----------------------------
# OUTPUT
# ----------------------------
print(json.dumps({
    "user": USER,
    "base_path": BASE_PATH,
    "total_folders": len(folders),
    "folders": folders
}))