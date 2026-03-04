#!/bin/bash

BASE="/usr/local/painelstream/templates/icecast-base.xml"
OUTPUT="/etc/icecast2/icecast.xml"

# Remove última linha </icecast> do base
sed '$d' "$BASE" > "$OUTPUT"

# Adiciona mounts
for file in /home/*/config/mount.xml; do
    [ -f "$file" ] && cat "$file" >> "$OUTPUT"
done

# Fecha XML
echo "</icecast>" >> "$OUTPUT"

# Permissões
chown root:icecast "$OUTPUT"
chmod 644 "$OUTPUT"

xmllint --format "$OUTPUT" -o "$OUTPUT"

systemctl reload icecast2
