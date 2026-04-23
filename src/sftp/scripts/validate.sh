#!/bin/sh

FILE="$1"

case "$FILE" in
  *.mp3) exit 0 ;;
  *) echo "Apenas arquivos MP3 permitidos"; exit 1 ;;
esac