import os
import subprocess
import sys

# pega usuário passado no comando
if len(sys.argv) < 2:
    print("Uso: python3 script.py usuario")
    sys.exit(1)

USUARIO = sys.argv[1]

PASTA_BASE = f"/home/{USUARIO}/ftp/pastas"

def run_ffmpeg_check(path):
    result = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "null", "-"],
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE
    )
    return result.stderr.decode().strip()

def is_mp3(file):
    return file.lower().endswith(".mp3")

def reconverter_audio(path):
    temp = path + ".tmp"

    cmd = [
        "ffmpeg", "-y",
        "-err_detect", "ignore_err",
        "-i", path,
        "-vn",
        "-map_metadata", "-1",   # 🔥 remove metadados bugados
        "-ar", "44100",
        "-ac", "2",
        "-b:a", "128k",
        "-f", "mp3",
        temp
    ]

    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # valida arquivo gerado
    if os.path.exists(temp) and os.path.getsize(temp) > 100000:
        os.replace(temp, path)  # 🔥 substitui mantendo o MESMO nome
        return True

    if os.path.exists(temp):
        os.remove(temp)

    return False

def processar():
    for root, dirs, files in os.walk(PASTA_BASE):
        for file in files:
            full = os.path.join(root, file)

            # ❌ remove tudo que não for mp3
            if not is_mp3(file):
                print(f"Removendo não-MP3: {full}")
                try:
                    os.remove(full)
                except:
                    pass
                continue

            print(f"Verificando: {full}")

            erro = run_ffmpeg_check(full)

            if erro:
                print(f"Erro detectado")

                # tenta recuperar
                if reconverter_audio(full):
                    print(f"Recuperado (mesmo nome)")
                    
                    # valida novamente
                    erro2 = run_ffmpeg_check(full)
                    if erro2:
                        print(f"Ainda ruim → removendo")
                        os.remove(full)
                else:
                    print(f"Irrecuperável → removendo")
                    os.remove(full)

if __name__ == "__main__":
    processar()
    print("Finalizado com segurança!")