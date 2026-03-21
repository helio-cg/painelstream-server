#!/usr/bin/env bash

[[ -n "${LIB_MESSAGES_LOADED:-}" ]] && return
LIB_MESSAGES_LOADED=1

json() {
    printf '{"status":"%s","message":"%s"}\n' "$1" "$2"
}

erro() {
    local MESSAGE="$1"
    local DATA="${2:-}"

    if [[ -n "$DATA" ]]; then
        printf '{"status":"error","message":"%s","data":%s}\n' "$MESSAGE" "$DATA"
    else
        printf '{"status":"error","message":"%s"}\n' "$MESSAGE"
    fi
    exit 1
}

sucesso() {
    local MESSAGE="$1"
    local DATA="${2:-}"

    if [[ -n "$DATA" ]]; then
        printf '{"status":"success","message":"%s","data":%s}\n' "$MESSAGE" "$DATA"
    else
        printf '{"status":"success","message":"%s"}\n' "$MESSAGE"
    fi
    exit 0
}