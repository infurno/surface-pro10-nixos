#!/usr/bin/env bash
# =============================================================================
# Surface Pro 10 - Quick Wi-Fi Connection Helper
# =============================================================================
set -euo pipefail

if command -v serpantinum >/dev/null 2>&1; then
    # Try opening Serpantinum's native Wi-Fi panel first
    serpantinum msg open network wifi 2>/dev/null && exit 0
fi

# Fallback: Launch terminal touch-friendly nmtui or nm-connection-editor
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v nm-connection-editor >/dev/null 2>&1; then
    nm-connection-editor &
elif command -v nmtui >/dev/null 2>&1; then
    nmtui
else
    echo "Scanning Wi-Fi networks..."
    nmcli device wifi list
    read -rp "Enter SSID: " SSID
    read -rsp "Enter Password: " PASS
    echo ""
    nmcli device wifi connect "$SSID" password "$PASS"
fi
