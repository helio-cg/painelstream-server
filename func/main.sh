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

require() {
    local value="$1"
    local message="${2:-Campo obrigatório não informado}"

    if [[ -z "${value:-}" ]]; then
        erro "$message"
    fi
}

is_user_free() {
    #local USERNAME="$1"

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
    #local PASS="$1"
    [[ -z "${PASSWORD:-}" ]] && { erro "Senha obrigatoria"; return 1; }
    [[ "${PASSWORD:-}" =~ [[:space:]] ]] && { erro "senha nao pode conter espacos"; return 1; }
    return 0
}

validate_quota() {
    #local QUOTA_GB="$1"

[[ -z "${QUOTA_GB:-}" ]] && { erro "quota obrigatoria"; return 1; }


    # deve ser inteiro
    if ! is_number "$QUOTA_GB"; then
        erro "quota deve ser um numero inteiro"
        return 1
    fi

    return 0
}

validate_listeners() {
    #local LISTENERS="$1"

[[ -z "${LISTENERS:-}" ]] && { erro "listeners obrigatoria"; return 1; }


    # deve ser número inteiro
    if ! is_number "$LISTENERS"; then
        erro "listeners deve ser um numero inteiro"
        return 1
    fi

    # passou nas verificações
    return 0
}

generate_random_password() {
    # Generate a secure random password using multiple methods with fallbacks
    local password=""
    
    # Try using openssl (most reliable, available on most systems)
    if command -v openssl >/dev/null 2>&1; then
        password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    # Fallback to /dev/urandom with tr (most Linux systems)
    elif [ -r /dev/urandom ]; then
        password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)
    # Last resort fallback using date and simple hashing
    else
        if command -v sha256sum >/dev/null 2>&1; then
            password=$(date +%s%N | sha256sum | base64 | head -c 32)
        elif command -v shasum >/dev/null 2>&1; then
            password=$(date +%s%N | shasum -a 256 | base64 | head -c 32)
        else
            # Very basic fallback - combines multiple sources of entropy
            password=$(echo "$(date +%s%N)-$(hostname)-$$-$RANDOM" | base64 | tr -d "=+/" | head -c 32)
        fi
    fi
    
    # Ensure we got a password of correct length
    if [ -z "$password" ] || [ ${#password} -lt 20 ]; then
        echo "Error: Failed to generate random password" >&2
        exit 1
    fi
    
    echo "$password"
}