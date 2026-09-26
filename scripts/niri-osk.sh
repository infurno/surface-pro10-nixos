#!/bin/sh
# wvkbd on-screen keyboard toggle for niri, orientation-aware.
#
#   niri-osk.sh          toggle the keyboard
#   niri-osk.sh resize   if the keyboard is up, restart it at the height
#                        matching the current output orientation
#
# Called from the 4-finger swipe-up gesture and from niri-rotate.sh.

BIN="${WVKBD_BIN:-$(command -v wvkbd-mobintl || command -v wvkbd-deskintl || echo wvkbd-mobintl)}"
OUTPUT="${NIRI_OUTPUT:-eDP-1}"
H_LANDSCAPE=300
H_PORTRAIT=520

# Resolve the running niri instance's IPC socket (newest first).
SOCKET=$(ls -t "/run/user/$(id -u)"/niri.wayland-*.sock 2>/dev/null | head -1)
[ -n "$SOCKET" ] && export NIRI_SOCKET="$SOCKET"

height_for_orientation() {
    T=$(niri msg -j outputs 2>/dev/null | python3 -c \
        "import json,sys; print(json.load(sys.stdin).get('$OUTPUT', {}).get('logical', {}).get('transform', 'normal'))" 2>/dev/null)
    case "$T" in
        90 | 270) echo "$H_PORTRAIT" ;;
        *) echo "$H_LANDSCAPE" ;;
    esac
}

case "${1:-toggle}" in
    toggle)
        if pgrep -x "$(basename "$BIN")" >/dev/null 2>&1; then
            pkill -x "$(basename "$BIN")"
        else
            "$BIN" -L "$(height_for_orientation)" --bg 1a1b26 --fg c0caf5 >/dev/null 2>&1 &
        fi
        ;;
    resize)
        if pgrep -x "$(basename "$BIN")" >/dev/null 2>&1; then
            pkill -x "$(basename "$BIN")"
            sleep 0.3
            "$BIN" -L "$(height_for_orientation)" --bg 1a1b26 --fg c0caf5 >/dev/null 2>&1 &
        fi
        ;;
esac
