#!/usr/bin/env bash

BASE="/home"
GROUP="radiosftp"
FS_MOUNT="/"
SHELL="/usr/sbin/nologin"
PAINELSTREAM="/usr/local/painelstream"

json() {
    printf '{"status":"%s","message":"%s"}\n' "$1" "$2"
}

erro() {
    local MESSAGE="$1"
    local DATA="$2"

    if [[ -n "$DATA" ]]; then
        printf '{"status":"error","message":"%s","data":%s}\n' "$MESSAGE" "$DATA"
    else
        printf '{"status":"error","message":"%s"}\n' "$MESSAGE"
    fi
    exit 1
}

sucesso() {
    local MESSAGE="$1"
    local DATA="$2"

    if [[ -n "$DATA" ]]; then
        printf '{"status":"success","message":"%s","data":%s}\n' "$MESSAGE" "$DATA"
    else
        printf '{"status":"success","message":"%s"}\n' "$MESSAGE"
    fi
    exit 0
}

validar_usuario() {
    local USERNAME="$1"
    local PASS="$2"

    [[ -z "$USERNAME" ]] && erro "usuario obrigatorio"
    [[ ! "$USERNAME" =~ ^[a-z]{6,10}$ ]] && erro "usuario invalido"
    id "$USERNAME" &>/dev/null && erro "usuario ja existe"
    [[ -z "$PASS" ]] && erro "senha obrigatoria"
}

validar_usuario_pass() {
    local USERNAME="$1"
    local PASS="$2"

    [[ -z "$USERNAME" ]] && erro "usuario obrigatorio"
    [[ ! "$USERNAME" =~ ^[a-z]{6,10}$ ]] && erro "usuario invalido"
    ! id "$USERNAME" &>/dev/null && erro "usuario nao existe"
    [[ -z "$PASS" ]] && erro "senha obrigatoria"
}

validar_usuario_listeners() {
    local USERNAME="$1"
    local PASS="$2"
    local LISTENERS="$3"

    [[ -z "$USERNAME" ]] && erro "usuario obrigatorio"
    [[ ! "$USERNAME" =~ ^[a-z]{6,10}$ ]] && erro "usuario invalido"
    ! id "$USERNAME" &>/dev/null && erro "usuario nao existe"
    [[ -z "$PASS" ]] && erro "senha obrigatoria"
    [ -z "$LISTENERS" ] && erro "numero de ouvintes deve ser informado"
}
