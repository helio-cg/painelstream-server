#!/bin/bash

export PATH=$PATH:/usr/sbin:/sbin:/bin:/usr/bin

erro() {
    printf '{"status":"error","message":"%s"}\n' "$1"
    exit 1
}

# Se veio via SSH com command= no authorized_keys
if [ -n "$SSH_ORIGINAL_COMMAND" ]; then
    # ⚠️ versão segura (sem eval)
    read -r -a ARGS <<< "$SSH_ORIGINAL_COMMAND"
    set -- "${ARGS[@]}"
fi

ACTION="$1"
shift || true

# padrões
QUOTA_GB=1
LISTENERS=50

# argumentos base (podem não existir dependendo da ação)
PARAM1="${1:-}"
PARAM2="${2:-}"
PARAM3="${3:-}"
PARAM4="${4:-}"
shift 2 2>/dev/null || true

# 🔹 função reutilizável de flags
parse_flags() {
    for arg in "$@"; do
        case $arg in
            --quota=*)
                QUOTA_GB="${arg#*=}"
                ;;
            --listeners=*)
                LISTENERS="${arg#*=}"
                ;;
            --password=*)
                PASSWORD="${arg#*=}"
        esac
    done
}

# aplica flags
parse_flags "$@"

case "$ACTION" in
    create_user)
        [[ -z "$PARAM1" ]] && erro "usuario obrigatorio"
        [[ -z "$PARAM2" ]] && erro "senha obrigatoria"

        /usr/local/painelstream/bin/ps-user-add \
            "$PARAM1" "$PARAM2" "$QUOTA_GB" "$LISTENERS"
        ;;
    update_user)
        [[ -z "$PARAM1" ]] && erro "usuario obrigatorio"

        /usr/local/painelstream/bin/ps-user-update "$PARAM1" "$PARAM2"
        ;;
    change_password)
        [[ -z "$PARAM1" ]] && erro "usuario obrigatorio"
        [[ -z "$PARAM2" ]] && erro "nova senha obrigatoria"

        /usr/local/painelstream/bin/ps-user-change-password "$PARAM1" "$PARAM2"
        ;;
    reload_icecast)
        systemctl reload icecast2
        ;;
    *)
        erro "Invalid action"
        ;;
esac