#!/bin/bash

BASE="/usr/local/painelstream/templates/icecast-base.xml"
OUTPUT="/etc/icecast2/icecast.xml"

echo "Gerando novo icecast.xml..."

# Começa com base
cat "$BASE" > "$OUTPUT"

# Procura todos radio*.xml
for file in /home/*/config/mount.xml; do
    if [ -f "$file" ]; then
        echo "Incluindo $file"
        cat "$file" >> "$OUTPUT"
    fi
done

# Fecha tag icecast se necessário
echo "</icecast>" >> "$OUTPUT"

# Ajusta permissões
chown root:icecast "$OUTPUT"
chmod 644 "$OUTPUT"

echo "Reload Icecast..."
systemctl reload icecast2

echo "Concluído!"