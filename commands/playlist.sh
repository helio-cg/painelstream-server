#!/usr/bin/env bash
[[ -n "${CMD_PLAYLIST_LOADED:-}" ]] && return
CMD_PLAYLIST_LOADED=1

cmd_playlist() {
    local ACTION="$1"
    shift || true

    parse_flags "$@"

    case "$ACTION" in
        create_playlist)
            require "$USER" "usuario obrigatorio"
            require "$PLAYLIST_PATH" "caminho da playlist obrigatorio"
            /usr/local/painelstream/bin/ps-playlist-add "$USER" "$PLAYLIST_PATH"
            log_action "create_playlist" "$USER"
            sucesso "playlist criada"
            ;;
        update_playlist)
            require "$USER" "usuario obrigatorio"
            require "$PLAYLIST_PATH" "caminho da playlist obrigatorio"
            /usr/local/painelstream/bin/ps-playlist-update "$USER" "$PLAYLIST_PATH"
            log_action "update_playlist" "$USER"
            sucesso "playlist atualizada"
            ;;
        *)
            erro "acao invalida para playlist"
            ;;
    esac
}