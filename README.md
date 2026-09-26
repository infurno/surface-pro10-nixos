# Surface Pro 10 for Business - Fedora Setup

Automated post-install setup for **Fedora (Plasma Spin / Workstation)** on the **Microsoft Surface Pro 10 for Business** (Intel Core Ultra 5 135U, Intel Arc Xe Graphics, Intel AI Boost NPU, 16 GB RAM, 2 TB NVMe).

This branch configures:
- **`linux-surface` Kernel & IPTS**: Native multi-touch, Surface Slim Pen 2 digitizer, thermal controls, and SAM cover dock.
- **Surface Pro Flex Keyboard**: Pre-shared Bluetooth cryptographic keys injected into BlueZ so detached wireless typing and haptic trackpad work without manual pairing.
- **`niri-tablet`**: Scrollable-tiling Wayland compositor compiled with all 20 touchscreen gesture patches (3-finger horizontal resize, 3-finger vertical carousel, edge swipes).
- **Orientation-Aware OSK**: Bottom swipe-up toggles `wvkbd`, dynamically resized between portrait and landscape.
- **Display Auto-Rotation**: Background user service that synchronizes screen orientation with the accelerometer via `iio-sensor-proxy`.
- **Intel Xe Graphics Hardware Acceleration**: Native VA-API video decode and compute runtime.

---

## Quick Start on Fedora

Once Fedora (e.g. Fedora Plasma Spin) is installed and connected to Wi-Fi, open a terminal and run:

```bash
# 1. Clone this repository (fedora branch)
git clone -b fedora https://github.com/<YOUR_USER>/surface-pro10-nixos.git
cd surface-pro10-nixos

# 2. Run the automated Fedora installer
./install-fedora.sh
```

---

## What the Installer Does

1. **Enables the official `linux-surface` Fedora repository**:
   - Installs `kernel-surface`, `iptsd`, `libwacom-surface`, `surface-control`, and `surface-secureboot`.
   - Enables and starts `iptsd` for touchscreen multi-touch and pen tracking.
2. **Injects Flex Keyboard Bluetooth Link Keys**:
   - Provisions `/var/lib/bluetooth/40:C7:3C:2F:8D:6F/FE:C5:9D:FC:98:83/info` with pre-shared LTK, IRK, CSRK, and EDIV/ERAND keys.
3. **Installs System & Desktop Packages**:
   - `waybar`, `fuzzel`, `mako`, `brightnessctl`, `iio-sensor-proxy`, `intel-media-driver`, `libva-utils`, `alacritty`.
   - Installs `wvkbd` (via Copr or builds from source).
4. **Compiles & Installs `niri-tablet`**:
   - Clones upstream `niri` release `v26.04`.
   - Applies the 20 touchscreen gesture patches from `patches/`.
   - Builds with `cargo build --release` and installs to `/usr/local/bin/niri`.
   - Installs `niri.desktop` into `/usr/share/wayland-sessions/`.
5. **Deploys Helpers & Auto-Rotation Service**:
   - Installs `niri-osk.sh` and `niri-rotate.sh` to `~/.local/bin/`.
   - Enables the systemd user service `niri-rotate.service`.
6. **Deploys Tablet Dotfiles**:
   - `~/.config/niri/config.kdl` (120Hz display scaling, gestures, edge swipes).
   - `~/.config/waybar/` (44px touch-padded bar with OSK launcher, battery, volume).
   - `~/.config/fuzzel/` (touch launcher).

---

## Post-Install Steps

### 1. Reboot into the Surface Kernel
```bash
sudo reboot
```

### 2. Secure Boot MOK Enrollment (If Secure Boot is Enabled)
Upon rebooting, a blue **MOKManagement** screen will appear:
1. Select **Enroll MOK**.
2. Select **Continue**.
3. Select **Yes**.
4. Enter password: `surface`.
5. Select **Reboot**.

### 3. Log In to Niri
At the SDDM / GDM login screen:
1. Click your username.
2. Select **Niri** from the session list (usually bottom-left or gear icon).
3. Enter your password.

### 4. Wireless Flex Keyboard Connection
- Detach the Flex Keyboard from the Surface Pro 10.
- Press and hold the **`Esc` key** for **4 seconds** until the **Fn LED flashes**.
- BlueZ will automatically authenticate the pre-shared LTK. Wireless typing and the haptic trackpad will activate immediately.
- Docking the keyboard magnetically switches back to hardwired mode and charges the battery.

---

## Touch Gestures Reference

| Gesture | Action |
| :--- | :--- |
| **3-Finger Drag (Horizontal)** | 1:1 Live window width resize (or view scroll) |
| **3-Finger Drag (Vertical)** | Fluid workspace carousel scroll |
| **3-Finger Tap** | Maximize / restore focused column |
| **4-Finger Tap** | Toggle Niri overview |
| **4-Finger Flick Down** | Close focused window |
| **4-Finger Flick Up** | Fullscreen window |
| **3-Finger Hold (~400ms) + Swipe** | Move window across columns or workspaces |
| **Bottom Edge Swipe Up** | Toggle orientation-aware On-Screen Keyboard (`wvkbd`) |
| **Top Edge Swipe Down** | Toggle touch application launcher (`fuzzel`) |
| **Left / Right Edge Swipe** | Focus column left / right |
