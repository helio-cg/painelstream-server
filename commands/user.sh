#!/usr/bin/env bash
[[ -n "${CMD_USER_LOADED:-}" ]] && return
CMD_USER_LOADED=1

cmd_user() {
    local ACTION="$1"
    shift || true

    parse_flags "$@"

    case "$ACTION" in
        create_user)
            is_user_free "$USER" "usuario obrigatorio"
            is_password_valid "$PASSWORD" "senha obrigatoria"
            validate_quota "$QUOTA_GB" || erro "quota invalida"
            validate_listeners "$LISTENERS" || erro "listeners invalido"

            /usr/local/painelstream/bin/ps-user-add "$USER" "$PASSWORD" "$QUOTA_GB" "$LISTENERS"
            log_action "create_user" "$USER"
            sucesso "usuario criado"
            ;;
        update_user)
            require "$USER" "usuario obrigatorio"

            # Opcional: verificar se o usuário realmente existe antes de atualizar
            if ! getent passwd "$USER" > /dev/null; then
                erro "usuario $USER nao encontrado"
            fi
            
            /usr/local/painelstream/bin/ps-user-update "$USER"
            log_action "update_user" "$USER"
            sucesso "usuario atualizado"
            ;;
        change_password)
            require "$USER" "usuario obrigatorio"
            is_password_valid "$PASSWORD" "nova senha obrigatoria"
            /usr/local/painelstream/bin/ps-user-change-password "$USER" "$PASSWORD"
            log_action "change_password" "$USER"
            sucesso "senha alterada"
            ;;
        *)
            erro "acao invalida para user"
            ;;
    esac
}