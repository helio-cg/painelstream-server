#!/bin/bash

ACTION=$1
PARAM1=$2
PARAM2=$3
PARAM3="${4:-}"
PARAM4="${5:-}"

case "$ACTION" in
    create_user)
        /usr/local/painelstream/bin/ps-user-add "$PARAM1" "$PARAM2" "$PARAM3"
        ;;
    update_user)
        /usr/local/painelstream/bin/ps-user-update "$PARAM1" "$PARAM2"
        ;;
    reload_icecast)
        systemctl reload icecast2
        ;;
    *)
        echo '{"success":false,"message":"Invalid action"}'
        exit 1
        ;;
esac