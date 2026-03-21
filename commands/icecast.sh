#!/usr/bin/env bash
[[ -n "${CMD_ICECAST_LOADED:-}" ]] && return
CMD_ICECAST_LOADED=1

cmd_icecast_reload() {
    systemctl reload icecast2
    log_action "reload_icecast" "system"
    sucesso "icecast recarregado"
}