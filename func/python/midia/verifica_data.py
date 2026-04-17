#!/usr/bin/env python3
import os
import base64
import hashlib
import json

BASE_DIR_TEMPLATE = "/home/{user}/ftp/pastas"
CONF_TEMPLATE = "/home/{user}/cache/{inode}.json"

IGNORE_DIRS = {'.git', '.cache', '.config', '__pycache__'}


def decode_base64(value):
    try:
        return base64.b64decode(value).decode('utf-8').strip()
    except:
        return value


def gerar_id(full_path):
    try:
        stat = os.stat(full_path)
        return f"{stat.st_dev}-{stat.st_ino}"
    except:
        return None


def folder_fingerprint(path):
    h = hashlib.md5()
    all_files = []

    for root, dirs, files in os.walk(path):
        dirs[:] = sorted([
            d for d in dirs
            if d not in IGNORE_DIRS and not d.startswith('.')
        ])

        for f in files:
            if not f.lower().endswith(".mp3"):
                continue

            full = os.path.join(root, f)

            try:
                stat = os.stat(full)
                all_files.append((full, f, stat.st_size, stat.st_mtime))
            except:
                continue

    all_files.sort(key=lambda x: x[0])

    for full, name, size, mtime in all_files:
        h.update(full.encode())
        h.update(name.encode())
        h.update(str(size).encode())
        h.update(str(mtime).encode())

    return h.hexdigest()


def verificar(username, pasta_b64):
    base_dir = BASE_DIR_TEMPLATE.format(user=username)

    rel_path = decode_base64(pasta_b64)
    dir_path = os.path.join(base_dir, rel_path)

    if not os.path.exists(dir_path):
        return {"status": "nao-existe", "id": None, "path": rel_path}

    folder_id = gerar_id(dir_path)

    if not folder_id:
        return {"status": "erro", "id": None, "path": rel_path}

    conf_path = CONF_TEMPLATE.format(user=username, inode=folder_id)

    current_fp = folder_fingerprint(dir_path)

    cached_fp = None

    if os.path.exists(conf_path):
        try:
            with open(conf_path) as f:
                cached = json.load(f)
                cached_fp = cached.get("fingerprint")
        except:
            cached_fp = None

    if cached_fp != current_fp:
        return {
            "status": "atualize",
            "id": folder_id,
            "path": rel_path,
            "fingerprint": current_fp
        }

    return {
        "status": "nao-atualize",
        "id": folder_id,
        "path": rel_path,
        "fingerprint": current_fp
    }