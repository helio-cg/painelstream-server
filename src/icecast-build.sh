#!/bin/bash
set -euo pipefail

BASE="/usr/local/painelstream/templates/icecast-base.xml"
OUTPUT="/etc/icecast2/icecast.xml"
BACKUP="/etc/icecast2/icecast.xml.bak"

# 🔒 Backup
cp "$OUTPUT" "$BACKUP"

# 🛠 Temp file
TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT

# 📄 Copia base SEM o fechamento </icecast>
sed '/<\/icecast>/d' "$BASE" > "$TMP_FILE"

# ➕ Adiciona mounts
for file in /home/*/configs/mount.xml; do
    if [ -f "$file" ]; then
        cat "$file" >> "$TMP_FILE"
    fi
done

# 🔚 Fecha corretamente
echo "</icecast>" >> "$TMP_FILE"

# 🧪 Validar XML
if ! xmllint --noout "$TMP_FILE" 2> /tmp/icecast_xml_error.log; then
    echo "XML inválido ❌" >&2
    cat /tmp/icecast_xml_error.log >&2
    exit 1
fi

# ✨ Formatar XML (opcional mas recomendado)
xmllint --format "$TMP_FILE" -o "$TMP_FILE"

# 🔐 Permissões
chown root:icecast "$TMP_FILE"
chmod 644 "$TMP_FILE"

# 🚀 Aplicar config
mv "$TMP_FILE" "$OUTPUT"

# 🔁 Reload com fallback
if ! systemctl reload icecast2; then

    # "Reload falhou ❌ tentando restart..." >&2

    if ! systemctl restart icecast2; then
       
       # echo "Erro total ❌ restaurando backup..." >&2

        cp "$BACKUP" "$OUTPUT"
        chown root:icecast "$OUTPUT"
        chmod 644 "$OUTPUT"

        systemctl restart icecast2

        exit 1
    fi
fi
