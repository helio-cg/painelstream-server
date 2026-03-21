#!/usr/bin/env bash
set -euo pipefail

BASE="/home"
GROUP="radiosftp"
FS_MOUNT="/"
DEFAULT_SHELL="/usr/sbin/nologin"
PAINELSTREAM="/usr/local/painelstream"

source "$PAINELSTREAM/func/libs/messages.sh"
source "$PAINELSTREAM/func/libs/helpers.sh"
source "$PAINELSTREAM/func/libs/logger.sh"
