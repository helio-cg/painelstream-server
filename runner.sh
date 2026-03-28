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
source "$PAINELSTREAM/func/main.sh"
source "$PAINELSTREAM/func/libs/logger.sh"
source "$PAINELSTREAM/func/libs/parse_flags.sh"

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

[ -z "$ACTION" ] && erro "acao obrigatoria"

# -------------------------
# Defaults
# -------------------------
#PS_USER=""
#PASSWORD=""
#QUOTA_GB=1
#LISTENERS=50

# parse global (APENAS AQUI)
parse_flags "$@"

# -------------------------
# Dispatch
# -------------------------
case "$ACTION" in
    create_user|update_user|change_password)
        cmd_user "$ACTION"
        ;;
    create_playlist|update_playlist)
        cmd_playlist "$ACTION"
        ;;
    reload_icecast)
        cmd_icecast_reload
        ;;
    *)
        erro "acao invalida"
        ;;
esac