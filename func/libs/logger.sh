#!/usr/bin/env bash
[[ -n "${LIB_LOGGER_LOADED:-}" ]] && return
LIB_LOGGER_LOADED=1

log_action() {
    local ACTION="$1"
    local USER="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ACTION=$ACTION USER=$USER" >> /var/log/painelstream.log
}