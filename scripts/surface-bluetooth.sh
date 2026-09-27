#!/usr/bin/env bash
# =============================================================================
# Surface Pro 10 - Bluetooth & Flex Keyboard Connection Helper
# =============================================================================
set -euo pipefail

FLEX_MAC="FE:C5:9D:FC:98:83"
HOST_MAC="40:C7:3C:2F:8D:6F"

echo "[1/4] Loading uhid kernel module (required for BLE keyboards)..."
sudo modprobe uhid 2>/dev/null || true

echo "[2/4] Unblocking Bluetooth hardware..."
sudo rfkill unblock bluetooth || true

echo "[3/4] Ensuring Bluetooth controller is powered on..."
bluetoothctl power on

echo "[4/4] Current Bluetooth Controller:"
bluetoothctl list

echo -e "\n------------------------------------------------------------"
echo "Surface Pro Flex Keyboard Reconnection Status"
echo "------------------------------------------------------------"
echo "Instructions:"
echo "1. Detach the Flex Keyboard from the Surface Pro 10."
echo "2. Hold down the ESC key on the keyboard for 4-5 seconds."
echo "3. Watch for the Fn key LED to flash."
echo "------------------------------------------------------------"

echo -e "\nAttempting connection to $FLEX_MAC..."
if bluetoothctl connect "$FLEX_MAC"; then
    echo "✓ Successfully connected to Surface Pro Flex Keyboard!"
    bluetoothctl info "$FLEX_MAC"
    exit 0
fi

echo -e "\n[!] Direct connection didn't succeed immediately."
echo "Ensuring device is trusted..."
bluetoothctl trust "$FLEX_MAC" 2>/dev/null || true

echo "Attempting to pair/re-pair..."
bluetoothctl pair "$FLEX_MAC" 2>/dev/null || true

if bluetoothctl connect "$FLEX_MAC"; then
    echo "✓ Connected after pairing!"
    bluetoothctl info "$FLEX_MAC"
    exit 0
fi

echo -e "\nScanning for Bluetooth devices for 10 seconds (ensure Esc was held on keyboard)..."
bluetoothctl --timeout 10 scan on || true

echo "Retrying connection..."
bluetoothctl connect "$FLEX_MAC" || {
    echo -e "\nIf the keyboard still fails to reconnect:"
    echo "Run: bluetoothctl remove $FLEX_MAC"
    echo "Then hold Esc for 5 seconds and run: bluetoothctl pair $FLEX_MAC"
}
