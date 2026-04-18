#!/usr/bin/env python3
import os
import json
import sys
import re
import base64

from func.python.midia._verifica_data import verificar

BASE_TEMPLATE = "/home/{user}/ftp/pastas"
OUTPUT_JSON = "/home/{user}/cache/folders.json"
CACHE_TEMPLATE = "/home/{user}/cache/{inode}.json"

IGNORE_DIRS = {'.git', '.cache', '.config', '__pycache__'}


def encode_base64(value):
    return base64.b64encode(value.encode()).decode()


def scan_folder(full_path):
    mp3_count = 0
    total_size = 0
    last_modified = 0

    for root, dirs, files in os.walk(full_path):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not d.startswith('.')]

        for file in files:
            if not file.lower().endswith('.mp3'):
                continue

            full_file = os.path.join(root, file)

            try:
                stat = os.stat(full_file)
                mp3_count += 1
                total_size += stat.st_size
                last_modified = max(last_modified, stat.st_mtime)
            except:
                continue

    return mp3_count, total_size, last_modified


if len(sys.argv) < 2:
    print(json.dumps({"error": "USER não informado"}))
    sys.exit(1)

USER = sys.argv[1]

if not re.match(r'^[a-z]{5,10}$', USER):
    print(json.dumps({"error": "USER inválido"}))
    sys.exit(1)

BASE_PATH = BASE_TEMPLATE.format(user=USER)

folders = []
logs = []

for root, dirs, files in os.walk(BASE_PATH):
    dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not d.startswith('.')]

    rel_path = os.path.relpath(root, BASE_PATH)

    if rel_path == ".":
        continue

    rel_b64 = encode_base64(rel_path)

    result = verificar(USER, rel_b64)

    folder_id = result["id"]
    status = result["status"]
    fingerprint = result["fingerprint"]

    cache_path = CACHE_TEMPLATE.format(user=USER, inode=folder_id)

    # ----------------------------
    # CACHE SEGURADO (NUNCA NULL REAL)
    # ----------------------------
    mp3_count = None
    total_size_gb = None
    last_modified = None

    if os.path.exists(cache_path):
        try:
            with open(cache_path) as f:
                cached = json.load(f)

            mp3_count = cached.get("mp3_count")
            total_size_gb = cached.get("total_size_gb")
            last_modified = cached.get("last_modified")
        except:
            pass

    cache_valid = (
        mp3_count is not None and
        total_size_gb is not None and
        last_modified is not None
    )

    # ----------------------------
    # LOG
    # ----------------------------
    logs.append({
        "pasta": rel_path,
        "id": folder_id,
        "status": status
    })

    # ----------------------------
    # DECISÃO
    # ----------------------------
    if status == "atualize" or not cache_valid:

        mp3_count, total_size, last_modified = scan_folder(root)
        total_size_gb = round(total_size / (1024 ** 3), 4)

        try:
            os.makedirs(os.path.dirname(cache_path), exist_ok=True)

            with open(cache_path, "w") as f:
                json.dump({
                    "fingerprint": fingerprint,
                    "mp3_count": mp3_count,
                    "total_size_gb": total_size_gb,
                    "last_modified": int(last_modified)
                }, f)
        except:
            pass

    else:
        # usa cache seguro
        mp3_count = int(mp3_count or 0)
        total_size_gb = float(total_size_gb or 0.0)
        last_modified = int(last_modified or 0)

    folders.append({
        "id": folder_id,
        "path": rel_path,
        "path_b64": rel_b64,
        "name": os.path.basename(rel_path),
        "depth": rel_path.count(os.sep) + 1,
        "mp3_count": mp3_count,
        "total_size_gb": total_size_gb,
        "last_modified": last_modified,
        "status": status
    })

folders.sort(key=lambda x: x["path"])

with open(OUTPUT_JSON.format(user=USER), "w") as f:
    json.dump({
        "user": USER,
        "folders": folders,
        "logs": logs
    }, f, indent=2)

print(json.dumps({
    "status": "ok",
    "total": len(folders)
}))