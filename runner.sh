#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/sbin:/usr/bin:/sbin:/bin"

# -------------------------
# SSH COMMAND PARSER (SAFE)
# -------------------------
if [ -n "${SSH_ORIGINAL_COMMAND:-}" ]; then
    eval "set -- $SSH_ORIGINAL_COMMAND"
fi

PAINELSTREAM="/usr/local/painelstream"

# -------------------------
# Carregar libs
# -------------------------
source "$PAINELSTREAM/func/libs/messages.sh"
source "$PAINELSTREAM/func/libs/helpers.sh"
source "$PAINELSTREAM/func/libs/logger.sh"

# -------------------------
# Carregar comandos
# -------------------------
source "$PAINELSTREAM/commands/user.sh"
source "$PAINELSTREAM/commands/playlist.sh"
source "$PAINELSTREAM/commands/icecast.sh"

# -------------------------
# Parse action
# -------------------------
ACTION="${1:-}"
shift || true

# -------------------------
# Defaults
# -------------------------
USER=""
PASSWORD=""
QUOTA_GB=1
LISTENERS=50

parse_flags "$@"

# -------------------------
# Dispatch
# -------------------------
case "$ACTION" in
    create_user|update_user|change_password) cmd_user "$ACTION" "$@" ;;
    create_playlist|update_playlist) cmd_playlist "$ACTION" "$@" ;;
    reload_icecast) cmd_icecast_reload ;;
    *) erro "acao invalida" ;;
esac