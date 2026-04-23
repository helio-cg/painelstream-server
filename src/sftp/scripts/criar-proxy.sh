#!/bin/bash

NAME=$1
PORT=$2

if [ -z "$NAME" ] || [ -z "$PORT" ]; then
  echo "Uso: radio-add nome porta"
  exit 1
fi

CONF_DIR="./nginx/includes/radios"
CONF_FILE="$CONF_DIR/$NAME.conf"

mkdir -p $CONF_DIR

cat > $CONF_FILE <<EOF
location /$NAME/ {
    proxy_pass http://host.docker.internal:$PORT/;

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
}
EOF

echo "🔧 Config criada: $CONF_FILE"

# 🔍 valida antes de aplicar
docker exec nginx nginx -t
if [ $? -ne 0 ]; then
  echo "❌ Erro na config! removendo..."
  rm -f $CONF_FILE
  exit 1
fi

# 🔁 reload seguro
docker exec nginx nginx -s reload

echo "✅ Rádio ativa em: /$NAME/"