#!/usr/bin/env python3
from mutagen.mp3 import MP3
import os
import sys
import base64
import subprocess
from utils import remover_caracteres

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

def main(username, pasta):
    decode = base64.b64decode(pasta).decode('utf-8').strip()
    diretorio = f"/home/{username}/ftp/pastas/{decode}/"

    if os.path.isdir(diretorio):

        comando = ["python3", "/var/www/src/modulos/verifica-data.py", username, pasta]

        response = ""
        try:
            resultado = subprocess.run(comando, check=True, text=True, capture_output=True)
            response = resultado.stdout.strip()
        except subprocess.CalledProcessError as e:
            print("Erro ao executar verifica-data:", e.stderr)

        if response == "atualize":

            print("🔍 Limpando e validando áudios...")

            for file in os.listdir(diretorio):
                full = os.path.join(diretorio, file)

                # ❌ Remove tudo que não for MP3
                if not file.lower().endswith(".mp3"):
                    print(f"Removendo não-MP3: {file}")
                    try:
                        os.remove(full)
                    except:
                        pass
                    continue

                # 🔧 Verifica integridade
                erro = verificar_audio(full)

                if erro:
                    print(f"Corrigindo: {file}")

                    if not corrigir_audio(full):
                        print(f"Removendo corrompido: {file}")
                        try:
                            os.remove(full)
                        except:
                            pass
                        continue

            # 🧹 (Opcional) limpar caracteres - com segurança
            for file in os.listdir(diretorio):
                if file.endswith(".mp3"):
                    original_file_path = os.path.join(diretorio, file)
                    new_file_name = remover_caracteres(file)
                    new_file_path = os.path.join(diretorio, new_file_name)

                    if original_file_path != new_file_path:
                        try:
                            os.rename(original_file_path, new_file_path)
                        except Exception as e:
                            print(f"Erro ao renomear {file}: {e}")

            # 📄 Gerar cache
            conf_file_path = f"/usr/local/hestia/data/users/{username}/music/{pasta}.conf"

            with open(conf_file_path, 'w') as fp:
                for filename in os.listdir(diretorio):
                    if filename.endswith('.mp3'):
                        full_file_name = os.path.join(diretorio, filename)

                        try:
                            audio = MP3(full_file_name)

                            if not hasattr(audio, 'info') or not hasattr(audio.info, 'length'):
                                print(f"Arquivo inválido: {filename}")
                                continue

                            tempo = (
                                str(int(audio.info.length // 3600)).zfill(2) + ':' +
                                str(int((audio.info.length % 3600) // 60)).zfill(2) + ':' +
                                str(int(audio.info.length % 60)).zfill(2)
                            )

                            playtime_seconds = audio.info.length

                        except Exception as e:
                            print(f"Erro ao processar {filename}: {e}")
                            continue

                        linha = f"tempo='{tempo}' filename='{filename}' folder='{decode}' playtime_seconds='{playtime_seconds}'\n"
                        fp.write(linha)

            print(f"✅ Updated: Pasta {decode} atualizada com sucesso")

    else:
        print(diretorio)
        print("❌ Retorno: usuário não existe ou diretório vazio.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: listar-musicas.py <username> <pasta>")
    else:
        main(sys.argv[1], sys.argv[2])