#!/usr/bin/env bash

BASE="/home"
GROUP="radiosftp"
FS_MOUNT="/"
DEFAULT_QUOTA_GB=1
SHELL="/usr/sbin/nologin"

check_args() {
    expected="$1"
    given="$2"
    usage="$3"

    if [ "$given" -lt "$expected" ]; then
        echo "Erro: argumentos insuficientes."
        echo "Uso: $0 $usage"
        exit 1
    fi
}