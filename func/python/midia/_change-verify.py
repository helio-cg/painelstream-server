#!/usr/bin/env python3
import sys
import os
import json
import time

from func.python.midia._verifica_data import verificar


def main(user, pasta_b64):

    result = verificar(user, pasta_b64)

    print(json.dumps(result))

    if result.get("status") == "atualize":

        folder_id = result.get("id")
        fingerprint = result.get("fingerprint")

        if not folder_id or not fingerprint:
            print(json.dumps({"error": "dados inválidos"}))
            return

        conf_path = f"/home/{user}/cache/{folder_id}.json"

        try:
            os.makedirs(os.path.dirname(conf_path), exist_ok=True)

            tmp = conf_path + ".tmp"

            with open(tmp, "w") as f:
                json.dump({
                    "fingerprint": fingerprint,
                    "updated_at": int(time.time())
                }, f)

            os.replace(tmp, conf_path)

            print(json.dumps({"conf": "atualizado"}))

        except Exception as e:
            print(json.dumps({"erro_conf": str(e)}))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: change-verify.py <user> <pasta_base64>")
        sys.exit(1)

    main(sys.argv[1], sys.argv[2])