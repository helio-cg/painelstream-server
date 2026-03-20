#!/usr/bin/env bash

BASE="/home"
GROUP="radiosftp"
FS_MOUNT="/"
DEFAULT_QUOTA_GB=1
DEFAULT_LISTENERS=50
SHELL="/usr/sbin/nologin"
PAINELSTREAM="/usr/local/painelstream"

validar_usuario() {
    local USERNAME="$1"

    # obrigatório
    if [[ -z "$USERNAME" ]]; then
        echo '{"status":"error","message":"usuario obrigatorio"}'
        exit 1
    fi

    # formato válido
    if [[ ! "$USERNAME" =~ ^[a-z]{6,10}$ ]]; then
        echo '{"status":"error","message":"usuario invalido"}'
        exit 1
    fi

    # já existe
    if id "$USERNAME" &>/dev/null; then
        echo '{"status":"error","message":"usuario ja existe"}'
        exit 1
    fi
}