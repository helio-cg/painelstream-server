#!/usr/bin/env bash

# Diretório do main.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Importa constants.sh relativo a main.sh
source "$SCRIPT_DIR/constants.sh"

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