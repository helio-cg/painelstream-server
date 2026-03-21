#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/sbin:/usr/bin:/sbin:/bin"

# -------------------------
# JSON OUTPUT
# -------------------------
erro() {
    printf '{"status":"error","message":"%s"}\n' "$1"
    exit 1
}

sucesso() {
    printf '{"status":"success","message":"%s"}\n' "$1"
    exit 0
}

# -------------------------
# SSH COMMAND PARSER (SAFE)
# -------------------------
if [ -n "${SSH_ORIGINAL_COMMAND:-}" ]; then
    # Usa eval seguro com set -- (preserva aspas corretamente)
    eval "set -- $SSH_ORIGINAL_COMMAND"
fi

ACTION="${1:-}"
shift || true

# -------------------------
# DEFAULTS
# -------------------------
USER=""
PASSWORD=""
QUOTA_GB=1
LISTENERS=50

# -------------------------
# FLAGS
# -------------------------
parse_flags() {
    for arg in "$@"; do
        case "$arg" in
            --user=*) USER="${arg#*=}" ;;
            --password=*) PASSWORD="${arg#*=}" ;;
            --quota=*) QUOTA_GB="${arg#*=}" ;;
            --listeners=*) LISTENERS="${arg#*=}" ;;
            *)
                erro "flag invalida: $arg"
                ;;
        esac
    done
}

parse_flags "$@"

# -------------------------
# VALIDAÇÕES
# -------------------------
require() {
    [[ -z "$1" ]] && erro "$2"
}

is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# -------------------------
# ACTIONS
# -------------------------
case "$ACTION" in

    create_user)
        require "$USER" "usuario obrigatorio"
        require "$PASSWORD" "senha obrigatoria"

        is_number "$QUOTA_GB" || erro "quota invalida"
        is_number "$LISTENERS" || erro "listeners invalido"

        /usr/local/painelstream/bin/ps-user-add \
            "$USER" "$PASSWORD" "$QUOTA_GB" "$LISTENERS"

        sucesso "usuario criado"
        ;;

    update_user)
        require "$USER" "usuario obrigatorio"

        /usr/local/painelstream/bin/ps-user-update "$USER"

        sucesso "usuario atualizado"
        ;;

    change_password)
        require "$USER" "usuario obrigatorio"
        require "$PASSWORD" "nova senha obrigatoria"

        /usr/local/painelstream/bin/ps-user-change-password "$USER" "$PASSWORD"

        sucesso "senha alterada"
        ;;

    reload_icecast)
        systemctl reload icecast2
        sucesso "icecast recarregado"
        ;;

    *)
        erro "acao invalida"
        ;;
esac