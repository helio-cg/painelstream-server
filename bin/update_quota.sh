#!/bin/bash
CONFIG="/usr/local/painelstream-server/func/main.sh"
source "$CONFIG"

USER="$1"
QUOTA_GB="$2"

[ -z "$QUOTA_GB" ] && echo "quota obrigatoria" && exit 1

KB=$((QUOTA_GB * 1024 * 1024))
setquota -u "$USER" "$KB" "$KB" 0 0 "$FS_MOUNT"

echo "quota atualizada"