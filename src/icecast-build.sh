#!/bin/bash

BASE="/usr/local/painelstream/templates/icecast-base.xml"
OUTPUT="/etc/icecast2/icecast.xml"
LOG="/var/log/icecast-config.log"

TMP=$(mktemp /tmp/icecast.XXXXXX.xml)
BACKUP=$(mktemp /tmp/icecast_backup.XXXXXX.xml)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando geração do icecast.xml" >> "$LOG"

# Backup atual
cp "$OUTPUT" "$BACKUP"

# Gera novo arquivo
sed '$d' "$BASE" > "$TMP"

for file in /home/*/config/mount.xml; do
    [ -f "$file" ] && cat "$file" >> "$TMP"
done

echo "</icecast>" >> "$TMP"

# Permissões
chown root:icecast "$TMP"
chmod 644 "$TMP"

# =========================
# VALIDAÇÃO
# =========================

ERROR=""

# Validação XML
if ! xmllint --noout "$TMP" 2>>"$LOG"; then
    ERROR="Erro de XML inválido"
fi

# Validação Icecast
if [ -z "$ERROR" ] && ! icecast2 -t -c "$TMP" 2>>"$LOG"; then
    ERROR="Erro na configuração do Icecast"
fi

# =========================
# DECISÃO FINAL
# =========================

if [ -z "$ERROR" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Configuração válida ✔" >> "$LOG"

    xmllint --format "$TMP" -o "$TMP"

    mv "$TMP" "$OUTPUT"

    systemctl reload icecast2

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Icecast recarregado com sucesso 🚀" >> "$LOG"

    rm -f "$BACKUP"

    exit 0
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERRO: $ERROR ❌" >> "$LOG"

    # Restaura backup
    cp "$BACKUP" "$OUTPUT"

    rm -f "$TMP"
    rm -f "$BACKUP"

    echo "Falha: $ERROR"
    exit 1
fi