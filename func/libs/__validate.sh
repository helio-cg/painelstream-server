#!/usr/bin/env bash

[[ -n "${LIB_VALIDATE_LOADED:-}" ]] && return
LIB_VALIDATE_LOADED=1

username_valid(){
    local USERNAME="$1"

    require "$USERNAME" "usuario obrigatorio"
    [[ ! "$USERNAME" =~ ^[a-z][a-z0-9_]{5,15}$ ]] && erro "usuario invalido"
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