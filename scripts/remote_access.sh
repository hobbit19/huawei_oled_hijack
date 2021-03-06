#!/system/bin/busybox sh

CONF_FILE="/data/remote_access"
CURRENT_MODE="$(cat $CONF_FILE)"
echo $CURRENT_MODE

enable_all () {
    iptables -D SERVICE_INPUT -p tcp --dport 80 -j REJECT
    iptables -D SERVICE_INPUT -p tcp --dport 23 -j REJECT
    iptables -D SERVICE_INPUT -p tcp --dport 5555 -j REJECT
    return 0
}

disable_web () {
    iptables -I SERVICE_INPUT -p tcp --dport 80 -j REJECT
    return 0
}

disable_telnet () {
    iptables -I SERVICE_INPUT -p tcp --dport 23 -j REJECT
    return 0
}

disable_adb () {
    iptables -I SERVICE_INPUT -p tcp --dport 5555 -j REJECT
    return 0
}

handle_state () {
    [[ "$CURRENT_MODE" == "0" ]] && enable_all
    [[ "$CURRENT_MODE" == "1" ]] && enable_all && disable_telnet && disable_adb
    [[ "$CURRENT_MODE" == "2" ]] && enable_all && disable_web
    [[ "$CURRENT_MODE" == "3" ]] && enable_all && disable_telnet && disable_adb && disable_web
    return 0
}

if [[ "$1" == "boot" ]]
then
    /system/bin/sleep 5
    handle_state
    exit 0
fi

if [[ "$1" == "get" ]]
then
    [[ "$CURRENT_MODE" == "0" ]] && exit 0
    [[ "$CURRENT_MODE" == "1" ]] && exit 1
    [[ "$CURRENT_MODE" == "2" ]] && exit 2
    [[ "$CURRENT_MODE" == "3" ]] && exit 3

    # assuming it's not configured yet, all ports open
    exit 0
fi

if [[ "$1" == "set_next" ]]
then
    if [[ "$CURRENT_MODE" == "0" ]] || [[ "$CURRENT_MODE" == "" ]]; then
        CURRENT_MODE="1" && echo "1" > $CONF_FILE
    elif [[ "$CURRENT_MODE" == "1" ]]; then
        CURRENT_MODE="2" && echo "2" > $CONF_FILE
    elif [[ "$CURRENT_MODE" == "2" ]]; then
        CURRENT_MODE="3" && echo "3" > $CONF_FILE
    elif [[ "$CURRENT_MODE" == "3" ]]; then
        CURRENT_MODE="0" && echo "0" > $CONF_FILE
    fi

    handle_state
fi
