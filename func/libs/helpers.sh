#!/usr/bin/env bash

[[ -n "${LIB_MESSAGES_LOADED:-}" ]] && return
LIB_MESSAGES_LOADED=1

require() {
    [[ -z "$1" ]] && erro "$2"
}

is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}