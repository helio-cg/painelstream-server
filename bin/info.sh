#!/bin/bash
CONFIG="/usr/local/painelstream-server/func/main.sh"
source "$CONFIG"

USER="$1"
UPLOAD_DIR="$BASE/$USER/uploads"

du -sh "$UPLOAD_DIR"
quota -u "$USER"