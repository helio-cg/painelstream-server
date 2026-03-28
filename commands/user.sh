#!/usr/bin/env bash
[[ -n "${CMD_USER_LOADED:-}" ]] && return
CMD_USER_LOADED=1

cmd_user() {
    local ACTION="$1"

    case "$ACTION" in
        create_user)
            is_user_free
            is_password_valid
            validate_quota
            validate_listeners

            /usr/local/painelstream/bin/ps-user-add "$USERNAME" "$PASSWORD" "$QUOTA_GB" "$LISTENERS"
           # log_action "create_user" "$USERNAME"
          #  sucesso "usuario criado"
            ;;
        update_user)
            require "$USERNAME" "usuario obrigatorio"

            if ! getent passwd "$USERNAME" > /dev/null; then
                erro "usuario $USERNAME nao encontrado"
            fi
            
            /usr/local/painelstream/bin/ps-user-update "$USERNAME"
            log_action "update_user" "$USERNAME"
            sucesso "usuario atualizado"
            ;;
        change_password)
            require "$USERNAME" "usuario obrigatorio"
            is_password_valid "$PASSWORD" "nova senha obrigatoria"

            /usr/local/painelstream/bin/ps-user-change-password "$USERNAME" "$PASSWORD"
            log_action "change_password" "$USERNAME"
            sucesso "senha alterada"
            ;;
        *)
            erro "acao invalida para user"
            ;;
    esac
}