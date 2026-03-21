#!/usr/bin/env bash
set -euo pipefail

BASE="/home"
GROUP="radiosftp"
FS_MOUNT="/"
DEFAULT_SHELL="/usr/sbin/nologin"
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

require() {
    local VALUE="$1"
    local MSG="$2"

    [[ -z "$VALUE" ]] && erro "$MSG"
}

username_valid(){
    local USERNAME="$1"

    require "$USERNAME" "usuario obrigatorio"
    [[ ! "$USERNAME" =~ ^[a-z]{6,10}$ ]] && erro "usuario invalido"
}

validar_usuario() {
    local USERNAME="$1"
    local PASS="$2"

    username_valid "$USERNAME"
    id "$USERNAME" &>/dev/null && erro "usuario ja existe"
    
    require "$PASS" "senha obrigatoria"
}

validar_usuario_pass() {
    local USERNAME="$1"
    local PASS="$2"

    username_valid "$USERNAME"
    ! id "$USERNAME" &>/dev/null && erro "usuario nao existe"

    require "$PASS" "senha obrigatoria"
}

validar_usuario_listeners() {
    local USERNAME="$1"
    local PASS="$2"
    local LISTENERS="$3"

    username_valid "$USERNAME"
    ! id "$USERNAME" &>/dev/null && erro "usuario nao existe"

    require "$PASS" "senha obrigatoria"
    
    [[ -z "$LISTENERS" || ! "$LISTENERS" =~ ^[0-9]+$ ]] && erro "listeners deve ser numero"
}
