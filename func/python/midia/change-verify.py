#!/usr/bin/env python3
import os
import sys
import base64

def main(username, pasta):
    # Define o caminho do arquivo
    filename = f"/usr/local/hestia/data/users/{username}/music/{pasta}.conf"

    # Decodifica a pasta
    decoded_pasta = base64.b64decode(pasta).decode('utf-8').strip()

    # Define o diretório
    dir_path = f"/home/{username}/ftp/pastas/{decoded_pasta}"

    # Obtém os tempos de modificação
    dirtime = os.path.getmtime(dir_path) if os.path.exists(dir_path) else None
    filetime = os.path.getmtime(filename) if os.path.exists(filename) else None

    if dirtime is not None and filetime is not None:
        if dirtime > filetime:
            print("atualize")
        else:
            print("nao-atualize")
    elif dirtime is not None and filetime is None:
        print("atualize")
    else:
        print("nao-existe")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: verifica-data.py <username> <pasta>")
    else:
        main(sys.argv[1], sys.argv[2])
