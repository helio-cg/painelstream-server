#!/bin/bash

NAME=$1

CONF_FILE="./nginx/includes/radios/$NAME.conf"

if [ ! -f "$CONF_FILE" ]; then
  echo "❌ Rádio não existe"
  exit 1
fi

rm -f $CONF_FILE

docker exec nginx nginx -t && docker exec nginx nginx -s reload

echo "🗑️ Rádio removida: $NAME"