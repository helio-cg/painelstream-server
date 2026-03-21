#!/usr/bin/env bash
# painelstream.sh
BASE="/home"
GROUP="radiosftp"
FS_MOUNT="/"
DEFAULT_SHELL="/usr/sbin/nologin"
PAINELSTREAM="/usr/local/painelstream"

erro() { echo "{\"status\":\"error\",\"message\":\"$1\"}" >&2; exit 1; }
sucesso() { echo "{\"status\":\"success\",\"message\":\"$1\",\"data\":{\"user\":\"$USERNAME\"}}"; exit 0; }
is_number() { [[ "$1" =~ ^[0-9]+$ ]]; }

is_user_free() {
    local USERNAME="$1"

    [[ -z "$USERNAME" ]] && { erro "usuario obrigatorio"; return 1; }
    [[ ! "$USERNAME" =~ ^[a-z]{5,10}$ ]] && { erro "usuario invalido"; return 1; }

    reserved_names=("aria" "aria_log" "mysql" "sudo")
    for value in "${reserved_names[@]}"; do
        [[ "${USERNAME,,}" == "$value" ]] && { erro "usuario reservado"; return 1; }
    done

    if getent passwd "$USERNAME" > /dev/null; then
        erro "usuario $USERNAME ja existe"
        return 1
    fi

    return 0
}

is_password_valid() {
    local PASS="$1"
    [[ -z "$PASS" ]] && { erro "senha obrigatoria"; return 1; }
    [[ "$PASS" =~ [[:space:]] ]] && { erro "senha nao pode conter espacos"; return 1; }
    return 0
}

validate_quota() {
    local QUOTA_GB="$1"

    # obrigatório
    if [[ -z "$QUOTA_GB" ]]; then
        erro "quota obrigatoria"
        return 1
    fi

    # deve ser inteiro
    if ! is_number "$QUOTA_GB"; then
        erro "quota deve ser um numero inteiro"
        return 1
    fi

    return 0
}

validate_listeners() {
    local LISTENERS="$1"

    # obrigatório
    if [[ -z "$LISTENERS" ]]; then
        erro "listeners obrigatorio"
        return 1
    fi

    # deve ser número inteiro
    if ! is_number "$LISTENERS"; then
        erro "listeners deve ser um numero inteiro"
        return 1
    fi

    # passou nas verificações
    return 0
}