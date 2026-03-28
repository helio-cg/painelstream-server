#!/usr/bin/env bash
[[ -n "${LIB_PARSE_FLAGS_LOADED:-}" ]] && return
LIB_PARSE_FLAGS_LOADED=1

parse_flags() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                USERNAME="$2"
                shift 2
                ;;
            --password)
                PASSWORD="$2"
                shift 2
                ;;
            --quota_gb)
                QUOTA_GB="$2"
                shift 2
                ;;
            --listeners)
                LISTENERS="$2"
                shift 2
                ;;
            *)
                erro "flag desconhecida: $1"
                ;;
        esac
    done
}