#!/bin/bash
CONFIG="/usr/local/painelstream/func/main.sh"
source "$CONFIG"

USER="$1"
HOME_DIR="$BASE/$USER"

pkill -u "$USER" 2>/dev/null
userdel "$USER" 2>/dev/null
rm -rf "$HOME_DIR"

echo "radio removida"