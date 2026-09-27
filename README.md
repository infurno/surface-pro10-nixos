# Surface Pro 10 for Business - NixOS Configuration

Production-grade, declarative NixOS Flake configuration tailored for the **Microsoft Surface Pro 10 for Business** (Intel Core Ultra 5 135U, Intel Arc Xe Graphics, Intel AI Boost NPU, 16 GB RAM, 2 TB NVMe).

This build integrates **[`niri-tablet`](https://github.com/GGEZUS/niri-tablet)** for native touchscreen gestures and provides pre-shared cryptographic keys for the **Surface Pro Flex Keyboard** so detached wireless Bluetooth typing works out of the box.

---

## Hardware & Feature Support

| Component | Hardware | Linux / NixOS Implementation |
| :--- | :--- | :--- |
| **CPU** | Intel Core Ultra 5 135U (14 cores, 18 threads) | Native Meteor Lake power scaling (`intel_pstate`) |
| **GPU** | Intel Graphics (4 Xe Cores, Xe-LPG) | Native `xe` / `i915`, `intel-media-driver` (VA-API / QSV) |
| **NPU** | Intel AI Boost (NPU 3720) | `intel_vpu` driver + `intel-npu-driver` (Level Zero / OpenVINO) |
| **Display** | 13" PixelSense Flow (2880×1920, 3:2, 120Hz) | 120Hz VRR, fractional scale 1.75 on Wayland |
| **Touchscreen**| Microsoft PixelSense Digitizer | `iptsd` daemon + `niri-tablet` multi-finger gesture patchset |
| **Stylus** | Surface Slim Pen 2 | Low-latency stylus tracking + cradle charging in keyboard |
| **Sensors** | Accelerometer, Gyroscope, ALS | `iio-sensor-proxy` + automatic display rotation daemon |
| **Keyboard** | Surface Pro Flex Keyboard (Detached & Docked) | Hardwired via SAM when docked; pre-shared BlueZ LTK when detached |
| **Audio** | Intel SoundWire / Realtek | Low-latency PipeWire + WirePlumber + SOF firmware |
| **Sleep** | Modern Standby (S0ix) + S4 Hibernation | `s2idle` + 24 GB Btrfs swapfile (`suspend-then-hibernate`) |
| **Boot / Storage** | Unencrypted Btrfs Subvolumes | Direct fast boot without initrd password prompts |

---

## Repository Structure

```text
.
├── flake.nix                     # Flake entrypoint & niri-tablet package overlay
├── flake.lock                    # Locked input revisions
├── configuration.nix             # Desktop session, PipeWire, users, greetd, daemons
├── hardware-surface.nix          # linux-surface kernel, IPTS, Xe GPU, NPU, power profiles
├── surface-flex-keyboard.nix     # Injected BlueZ keys for Host 40:C7:3C:2F:8D:6F / Device FE:C5:9D:FC:98:83
├── disko.nix                     # Declarative LUKS2 + Btrfs + 24 GB swapfile layout
├── install.sh                    # Automated installer for Dual-Boot or Full Wipe
├── patches/                      # All 20 niri-tablet touchscreen gesture patches
│   ├── 0001-feat-input-add-touchscreen-3-finger-swipe-gestures.patch
│   └── ... (0002-0020)
├── scripts/
│   ├── niri-osk.sh               # Orientation-aware on-screen keyboard toggle & resize
│   └── niri-rotate.sh            # Sensor-driven screen auto-rotation daemon
└── dotfiles/
    ├── niri/config.kdl           # Niri configuration: gestures, 120Hz scaling, edge swipes
    ├── waybar/config.jsonc       # Touch-padded (44px) status bar
    ├── waybar/style.css          # Waybar stylesheet
    ├── fuzzel/fuzzel.ini         # Large-target touch application launcher
    └── mako/config               # Touch notification daemon
```

---

## Pre-Installation (Windows 11)

1. **Disable BitLocker / Device Encryption**:
   - Go to **Windows Settings $\to$ Privacy & security $\to$ Device encryption** (or search "BitLocker").
   - Switch **Device encryption** to **Off** and wait for decryption to finish.
2. **Update Firmware**:
   - Run the **Surface app** and **Windows Update** to ensure the Surface Aggregator Module (SAM), EC, and touch digitizer firmwares are fully up to date.
3. **Shrink the Windows Partition**:
   - Open **Disk Management** (`Win + X` $\to$ Disk Management).
   - Right-click drive `C:` $\to$ **Shrink Volume...**.
   - Shrink by `1500000` MB (~1.5 TB for NixOS), leaving ~400–500 GB for Windows.
   - Leave the freed space as unallocated.

---

## Installation Walkthrough

### 1. Boot the NixOS Live USB
1. Shut down the Surface Pro 10.
2. Hold **Volume Up (+)**, tap **Power**, and release Volume Up when the Surface logo appears to enter UEFI.
3. Under **Security**, set **Secure Boot** to `None` (or *Microsoft & 3rd Party CA*).
4. Under **Boot configuration**, slide **USB Storage** to the top.
5. Plug in your NixOS USB installer and reboot.

### 2. Clone and Run Installer
Open a terminal in the NixOS live environment (`Ctrl + Alt + T`):

```bash
# Connect to Wi-Fi if needed (via NetworkManager or nmcli)
# Clone this repository:
git clone https://github.com/<YOUR_USER>/surface-pro10-nixos.git
cd surface-pro10-nixos

# Run the automated installation assistant:
sudo ./install.sh
```

Choose **Option 1 (Dual-Boot)** to install into the free space while preserving Windows 11, or **Option 2** if you wish to wipe the entire drive.

### 3. First Boot & Post-Install Setup
1. Reboot and select **NixOS** from the `systemd-boot` menu.
2. Log in with user `user` (password `nix`).
3. Change your password immediately:
   ```bash
   passwd
   ```

---

## Surface Pro Flex Keyboard Wireless Operation

Your keyboard’s paired keys are pre-configured:
- **Host Adapter**: `40:C7:3C:2F:8D:6F`
- **Keyboard MAC**: `FE:C5:9D:FC:98:83`

**How to connect wirelessly**:
1. Detach the Flex Keyboard from the Surface Pro 10.
2. Press and hold the **`Esc` key** for **4 seconds** until the **Fn LED flashes**.
3. BlueZ will automatically authenticate the pre-shared LTK. Wireless typing and the haptic trackpad will activate immediately.
4. Snapping the keyboard back onto the pogo pins seamlessly switches back to hardwired mode and charges the battery.

---

## Touchscreen Gestures Cheat Sheet

| Gesture | Action |
| :--- | :--- |
| **3-Finger Drag (Horizontal)** | 1:1 Live window width resize (or view scroll) |
| **3-Finger Drag (Vertical)** | Fluid workspace carousel scroll |
| **3-Finger Tap** | Maximize / restore focused column |
| **4-Finger Tap** | Toggle Niri overview |
| **4-Finger Flick Down** | Close focused window |
| **4-Finger Flick Up** | Fullscreen window |
| **3-Finger Press & Hold (~400ms) + Swipe** | Move window across columns or workspaces |
| **Bottom Edge Swipe Up** | Toggle orientation-aware On-Screen Keyboard (`wvkbd`) |
| **Top Edge Swipe Down** | Toggle touch application launcher (`fuzzel`) |
| **Left / Right Edge Swipe** | Focus column left / right |
