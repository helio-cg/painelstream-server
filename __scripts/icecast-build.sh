#!/bin/bash
set -euo pipefail

BASE="/var/www/src/templates/icecast.base.xml"
OUTPUT="/etc/icecast2/icecast.xml"
BACKUP="/etc/icecast2/icecast.xml.bak"

echo "Gerando novo icecast.xml..."

# 🔒 Backup do atual
cp "$OUTPUT" "$BACKUP"

# 🛠 Gera novo config em arquivo temporário
TMP_FILE=$(mktemp)

cat "$BASE" > "$TMP_FILE"

for file in /home/*/config/mount.xml; do
    if [ -f "$file" ]; then
        echo "Incluindo $file"
        cat "$file" >> "$TMP_FILE"
    fi
done

echo "</icecast>" >> "$TMP_FILE"

# 🔐 Permissões antes de mover
chown root:icecast "$TMP_FILE"
chmod 644 "$TMP_FILE"

# 🚀 Substitui config
mv "$TMP_FILE" "$OUTPUT"

echo "Reiniciando Icecast..."

# 🔍 Testa reload
if systemctl reload icecast2; then
    echo "Reload OK ✅"
else
    echo "Erro no reload ❌ tentando restart..."

    if systemctl restart icecast2; then
        echo "Restart OK ✅"
    else
        echo "Erro total ❌ restaurando backup..."

        cp "$BACKUP" "$OUTPUT"
        chown root:icecast "$OUTPUT"
        chmod 644 "$OUTPUT"

        systemctl restart icecast2

        echo "Backup restaurado e serviço recuperado ✅"
        exit 1
    fi
fi

echo "Concluído!"