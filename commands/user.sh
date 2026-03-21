#!/usr/bin/env bash
[[ -n "${CMD_USER_LOADED:-}" ]] && return
CMD_USER_LOADED=1

cmd_user() {
    local ACTION="$1"
    shift || true

    parse_flags "$@"

    case "$ACTION" in
        create_user)
            require "$USER" "usuario obrigatorio"
            require "$PASSWORD" "senha obrigatoria"
            is_number "$QUOTA_GB" || erro "quota invalida"
            is_number "$LISTENERS" || erro "listeners invalido"

            /usr/local/painelstream/bin/ps-user-add "$USER" "$PASSWORD" "$QUOTA_GB" "$LISTENERS"
            log_action "create_user" "$USER"
            sucesso "usuario criado"
            ;;
        update_user)
            require "$USER" "usuario obrigatorio"
            /usr/local/painelstream/bin/ps-user-update "$USER"
            log_action "update_user" "$USER"
            sucesso "usuario atualizado"
            ;;
        change_password)
            require "$USER" "usuario obrigatorio"
            require "$PASSWORD" "nova senha obrigatoria"
            /usr/local/painelstream/bin/ps-user-change-password "$USER" "$PASSWORD"
            log_action "change_password" "$USER"
            sucesso "senha alterada"
            ;;
        *)
            erro "acao invalida para user"
            ;;
    esac
}