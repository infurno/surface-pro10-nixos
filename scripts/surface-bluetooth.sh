#!/usr/bin/env bash
# =============================================================================
# Surface Pro 10 - Bluetooth & Flex Keyboard Connection Helper
# =============================================================================
set -euo pipefail

FLEX_MAC="FE:C5:9D:FC:98:83"

echo "[*] Unblocking Bluetooth hardware..."
sudo rfkill unblock bluetooth || true

echo "[*] Ensuring Bluetooth controller is powered on..."
bluetoothctl power on

echo "[*] Checking controller status..."
bluetoothctl list

echo -e "\nAttempting to connect to Surface Pro Flex Keyboard ($FLEX_MAC)..."
echo "Make sure the keyboard is detached and hold Esc for 4 seconds until the Fn LED flashes."

if bluetoothctl connect "$FLEX_MAC"; then
    echo "✓ Successfully connected to Surface Pro Flex Keyboard!"
    bluetoothctl info "$FLEX_MAC"
else
    echo "[!] Direct connection failed. Scanning for nearby devices..."
    bluetoothctl trust "$FLEX_MAC" 2>/dev/null || true
    echo "Running bluetoothctl connect again..."
    bluetoothctl connect "$FLEX_MAC" || {
        echo "Could not connect. Opening bluetoothctl prompt..."
        bluetoothctl
    }
fi
