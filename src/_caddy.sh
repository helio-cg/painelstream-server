#!/bin/bash

DOMAIN=$1
ROOT_PATH="/usr/local/painelstream"
CADDYFILE="/etc/caddy/Caddyfile"
TPL="/usr/local/painelstream/templates/caddy.tpl"

echo "Adicionando domínio ao Caddy..."

# Verifica se já existe
if grep -q "$DOMAIN" "$CADDYFILE"; then
    echo "Domínio já existe no Caddyfile."
    exit 0
fi

# Gera config temporária com substituição
TMP=$(mktemp)

sed -e "s|{{DOMAIN}}|$DOMAIN|g" \
    -e "s|{{ROOT_PATH}}|$ROOT_PATH|g" \
    "$TPL" > "$TMP"

# Garante quebra de linha antes de adicionar
echo "" | sudo tee -a "$CADDYFILE" > /dev/null

# Adiciona no final
sudo tee -a "$CADDYFILE" < "$TMP" > /dev/null

rm "$TMP"

echo "Recarregando Caddy..."
sudo systemctl reload caddy

echo "Concluído!"