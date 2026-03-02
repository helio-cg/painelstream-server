#!/bin/bash
set -e

echo "=== Instalando quota se necessário ==="
if ! dpkg -l | grep -qw quota; then
    apt update
    apt install -y quota
    mkdir /usr/local/painelstream
fi

PARTITIONS=("/")
[ -d /home ] && PARTITIONS+=("/home")

for PART in "${PARTITIONS[@]}"; do
    DEVICE=$(df "$PART" | tail -1 | awk '{print $1}')
    echo "Configurando quotas em $PART ($DEVICE)"

    if [ -z "$DEVICE" ]; then
        echo "Não foi possível detectar a partição de $PART, pulando..."
        continue
    fi

    # Escapa barras do DEVICE para sed
    DEVICE_ESCAPED=$(echo "$DEVICE" | sed 's/\//\\\//g')

    # Backup do fstab
    cp /etc/fstab /etc/fstab.bak

    # Substitui errors=remount-ro por errors=remount-ro,usrquota,grpquota
    # Verifica se já existe exatamente a string
    fstab_clean=$(grep -v '^\s*#' /etc/fstab | grep -E '\sext4\s')

    if echo "$fstab_clean" | grep -qE '(^|,)usrquota(,|$)' && \
        echo "$fstab_clean" | grep -qE '(^|,)grpquota(,|$)'; then
        echo "========================================================"
        echo "usrquota,grpquota já configurados no fstab para $DEVICE"
        echo "========================================================"
    else
        # Substitui errors=remount-ro apenas se não tiver a versão completa
        echo "========================================================"
        sed -i "s/errors=remount-ro/errors=remount-ro,usrquota,grpquota/" /etc/fstab
        echo "usrquota,grpquota adicionados ao fstab para $DEVICE"
        echo "========================================================"
    fi

    # Recarregar systemd e remontar
    systemctl daemon-reload
    mount -o remount "$PART"

    # Criar arquivos de quota externos
    touch "$PART/aquota.user" "$PART/aquota.group"
    chmod 600 "$PART/aquota.user" "$PART/aquota.group"

    # Inicializar quotas forçando arquivos externos
    quotacheck -cugmF vfsv0 "$PART"

    # Ativar quotas
    quotaon "$PART"

    echo "Quota ativada em $PART"

    repquota -a
done
