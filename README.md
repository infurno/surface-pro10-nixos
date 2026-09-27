# Surface Pro 10 for Business - NixOS (Serpantinum + niri-tablet)

Declarative NixOS configuration tailored for the **Microsoft Surface Pro 10 for Business** (Intel Core Ultra 5 135U, Intel Arc Xe Graphics, Intel AI Boost NPU, 16 GB RAM, 2 TB NVMe).

This build merges:
- **`niri-tablet`**: Native touchscreen gestures (3-finger continuous 1:1 window column resize, 3-finger vertical workspace carousel, edge swipes).
- **Serpantinum Desktop Shell**: Quickshell-powered desktop shell with the **Liquid Glass** theme, top modular bar, battery %, system panel, Wi-Fi, Bluetooth, notifications, and lockscreen.
- **Surface Pro Flex Keyboard**: Pre-shared cryptographic keys injected into BlueZ + headless `bt-agent` on the system bus for automatic detached wireless pairing.
- **Surface Pro 10 Hardware**: Patched `linux-surface` kernel, IPTS multi-touch daemon, Meteor Lake Arc Xe graphics acceleration, and Intel AI Boost NPU.
- **Orientation & Virtual Keyboard**: Sensor daemon (`iio-sensor-proxy`) syncing screen orientation, and bottom edge-swipe spawning `wvkbd`.

---

## Hardware & Feature Support

| Component | Hardware | Linux / NixOS Implementation |
| :--- | :--- | :--- |
| **CPU** | Intel Core Ultra 5 135U (14 cores, 18 threads) | Native Meteor Lake power scaling (`intel_pstate`) |
| **GPU** | Intel Graphics (4 Xe Cores, Xe-LPG) | Native `xe` / `i915`, `intel-media-driver` (VA-API / QSV) |
| **NPU** | Intel AI Boost (NPU 3720) | `intel_vpu` driver + `intel-npu-driver` (Level Zero / OpenVINO) |
| **Display** | 13" PixelSense Flow (2880×1920, 3:2, 120Hz) | 120Hz VRR, fractional scale 1.75 on Wayland |
| **Desktop Shell** | Serpantinum (`github:ilyamiro/serpantinum`) | Liquid Glass modular bar, system panel, launcher, notifications |
| **Touchscreen**| Microsoft PixelSense Digitizer | `iptsd` daemon + `niri-tablet` multi-finger gesture patchset |
| **Stylus** | Surface Slim Pen 2 | Low-latency stylus tracking + cradle charging in keyboard |
| **Sensors** | Accelerometer, Gyroscope, ALS | `iio-sensor-proxy` + automatic display rotation daemon |
| **Keyboard** | Surface Pro Flex Keyboard (Detached & Docked) | Hardwired via SAM when docked; pre-shared BlueZ LTK + `bt-agent` when detached |
| **Audio** | Intel SoundWire / Realtek | Low-latency PipeWire + WirePlumber + SOF firmware |
| **Sleep** | Modern Standby (S0ix) + S4 Hibernation | `s2idle` + 24 GB Btrfs swapfile (`suspend-then-hibernate`) |
| **Boot / Storage** | Unencrypted Btrfs Subvolumes | Direct fast boot without initrd password prompts |

---

## Repository Structure

```text
.
├── flake.nix                     # Flake entrypoint, inputs (nixpkgs, home-manager, serpantinum)
├── flake.lock                    # Locked input revisions
├── configuration.nix             # System config: PipeWire, users, greetd, bt-agent, helper scripts
├── home.nix                      # Home Manager: Serpantinum (Liquid Glass), GTK theme, dotfile mapping
├── hardware-surface.nix          # linux-surface kernel, IPTS, Xe GPU, NPU, power profiles
├── surface-flex-keyboard.nix     # Injected BlueZ keys for Host 40:C7:3C:2F:8D:6F / Device FE:C5:9D:FC:98:83
├── disko.nix                     # Declarative unencrypted Btrfs + 24 GB swapfile layout
├── install.sh                    # Automated installer for Dual-Boot or Full Wipe
├── patches/                      # All 20 niri-tablet touchscreen gesture patches
│   ├── 0001-feat-input-add-touchscreen-3-finger-swipe-gestures.patch
│   └── ... (0002-0020)
├── scripts/
│   ├── niri-osk.sh               # Orientation-aware on-screen keyboard toggle & resize
│   ├── niri-rotate.sh            # Sensor-driven screen auto-rotation daemon
│   ├── surface-wifi.sh           # Wi-Fi connection assistant
│   └── surface-bluetooth.sh      # Bluetooth & Flex Keyboard pairing helper
└── dotfiles/
    └── niri/config.kdl           # Niri config: Serpantinum layer rules, liquid glass, niri-tablet gestures
```

---

## How to Apply on Your Surface Pro 10

Open a terminal on your Surface Pro 10 (`Mod + Return` for Kitty):

```bash
# 1. Pull the merged configuration
cd /etc/nixos
sudo git pull origin main

# 2. Switch to the new configuration
sudo nixos-rebuild switch --flake .#surface-pro10
```

---

## Quick Helpers (Wi-Fi & Bluetooth)

- **Connect to Wi-Fi**:
  - Press `Super + Ctrl + W` to open Serpantinum's Wi-Fi quick panel.
  - Or run `surface-wifi` in the terminal to launch the interactive connection wizard.
- **Connect / Pair Bluetooth**:
  - Run `surface-bluetooth` in the terminal to wake the controller, unblock `rfkill`, and connect to the Flex Keyboard.
  - The background `bluetooth-agent` (`bt-agent -c NoInputNoOutput`) automatically authenticates incoming BLE requests without requiring manual PIN confirmation.

---

## Surface Pro Flex Keyboard Wireless Operation

Your keyboard’s paired keys are pre-configured:
- **Host Adapter**: `40:C7:3C:2F:8D:6F`
- **Keyboard MAC**: `FE:C5:9D:FC:98:83`

**How to connect wirelessly**:
1. Detach the Flex Keyboard from the Surface Pro 10.
2. Press and hold the **`Esc` key** for **4 seconds** until the **Fn LED flashes**.
3. BlueZ and `bt-agent` authenticate the pre-shared keys automatically. Wireless typing and the haptic trackpad will activate immediately.
4. Snapping the keyboard back onto the pogo pins seamlessly switches back to hardwired mode and charges the battery.

---

## Touchscreen Gestures Cheat Sheet

| Gesture | Action |
| :--- | :--- |
| **3-Finger Drag (Horizontal)** | 1:1 Live window width resize |
| **3-Finger Drag (Vertical)** | Fluid workspace carousel scroll |
| **3-Finger Tap** | Maximize / restore focused column |
| **4-Finger Tap** | Toggle Niri overview |
| **4-Finger Flick Down** | Close focused window |
| **4-Finger Flick Up** | Fullscreen window |
| **3-Finger Hold (~400ms) + Swipe** | Move window across columns or workspaces |
| **Bottom Edge Swipe Up** | Toggle orientation-aware On-Screen Keyboard (`wvkbd`) |
| **Top Edge Swipe Down** | Open Serpantinum launcher |
| **Left / Right Edge Swipe** | Focus column left / right |
