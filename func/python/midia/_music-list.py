#!/usr/bin/env python3
from mutagen.mp3 import MP3
import os
import sys
import base64
import subprocess
import json

from func.python.midia._utils import remover_caracteres


# ----------------------------
# BASE64 SAFE
# ----------------------------
def decode_base64(value):
    try:
        return base64.b64decode(value).decode("utf-8").strip()
    except:
        return value


# ----------------------------
# AUDIO CHECK
# ----------------------------
def verificar_audio(path):
    result = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "null", "-"],
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE
    )
    return result.stderr.decode().strip()


def corrigir_audio(path):
    temp = path + ".tmp"

    cmd = [
        "ffmpeg", "-y",
        "-err_detect", "ignore_err",
        "-i", path,
        "-vn",
        "-map_metadata", "-1",
        "-ar", "44100",
        "-ac", "2",
        "-b:a", "128k",
        temp
    ]

    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    if os.path.exists(temp) and os.path.getsize(temp) > 100000:
        os.replace(temp, path)
        return True

    if os.path.exists(temp):
        os.remove(temp)

    return False


# ----------------------------
# MAIN
# ----------------------------
def main(username, pasta_b64):

    # 🔥 sempre decodifica localmente (segurança)
    pasta = decode_base64(pasta_b64)
    diretorio = f"/home/{username}/ftp/pastas/{pasta}"

    if not os.path.isdir(diretorio):
        print(json.dumps({"error": "diretório inválido"}))
        return

    # ----------------------------
    # chama verifica-data (BASE64 original)
    # ----------------------------
    comando = [
        "python3",
        "/home/helio/GitHub/painelstream-server/verifica-data.py",
        username,
        pasta_b64
    ]

    try:
        resultado = subprocess.run(
            comando,
            text=True,
            capture_output=True,
            check=True
        )
        response = resultado.stdout.strip()

    except subprocess.CalledProcessError as e:
        print(json.dumps({
            "error": "falha no verifica-data",
            "stdout": e.stdout,
            "stderr": e.stderr,
            "code": e.returncode
        }))
        return

    except Exception as e:
        print(json.dumps({"error": str(e)}))
        return

    # ----------------------------
    # SEM MUDANÇA → PARA AQUI
    # ----------------------------
    if response != "atualize":
        print(json.dumps({"status": "nao-atualize"}))
        return

    print(json.dumps({"status": "processando"}))

    # ----------------------------
    # LIMPEZA + CORREÇÃO
    # ----------------------------
    for file in os.listdir(diretorio):

        full = os.path.join(diretorio, file)

        if not file.lower().endswith(".mp3"):
            try:
                os.remove(full)
            except:
                pass
            continue

        erro = verificar_audio(full)

        if erro:
            print(f"Corrigindo: {file}")

            if not corrigir_audio(full):
                try:
                    os.remove(full)
                except:
                    pass

    # ----------------------------
    # RENOMEAR SEGURAMENTE
    # ----------------------------
    for file in os.listdir(diretorio):
        if file.lower().endswith(".mp3"):

            old = os.path.join(diretorio, file)
            new_name = remover_caracteres(file)
            new = os.path.join(diretorio, new_name)

            if old != new:
                try:
                    os.rename(old, new)
                except:
                    pass

    # ----------------------------
    # METADATA FINAL
    # ----------------------------
    tracks = []

    for file in os.listdir(diretorio):
        if not file.lower().endswith(".mp3"):
            continue

        full = os.path.join(diretorio, file)

        try:
            audio = MP3(full)

            if not hasattr(audio, "info") or not hasattr(audio.info, "length"):
                continue

            duration = audio.info.length
            size_mb = round(os.path.getsize(full) / (1024 * 1024), 2)

            tracks.append({
                "filename": file,
                "duration_seconds": duration,
                "duration_hms": f"{int(duration//3600):02}:{int((duration%3600)//60):02}:{int(duration%60):02}",
                "size_mb": size_mb
            })

        except:
            continue

    print(json.dumps({
        "status": "atualizado",
        "folder": pasta,
        "tracks": tracks,
        "total": len(tracks)
    }))


# ----------------------------
# CLI
# ----------------------------
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: listar-musicas.py <username> <pasta_base64>")
    else:
        main(sys.argv[1], sys.argv[2])