#!/usr/bin/env bash
# =============================================================================
# Surface Pro 10 for Business - Fedora Automated Installer
# linux-surface kernel, iptsd, Flex Keyboard BLE keys, niri-tablet, auto-rotate
# =============================================================================
set -euo pipefail

# ANSI Colors
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
RESET="\033[0m"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "${BOLD}${BLUE}================================================================${RESET}"
echo -e "${BOLD}${BLUE}   Surface Pro 10 for Business - Fedora Post-Install Setup     ${RESET}"
echo -e "${BOLD}${BLUE}================================================================${RESET}"
echo -e "Configuring system for user: ${GREEN}${REAL_USER}${RESET} (Home: ${USER_HOME})"

# -----------------------------------------------------------------------------
# 1. linux-surface Kernel & Touchscreen Drivers
# -----------------------------------------------------------------------------
echo -e "\n${BOLD}[1/7] Adding linux-surface DNF repository & installing drivers...${RESET}"
sudo dnf config-manager addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo 2>/dev/null || \
sudo dnf config-manager --add-repo https://pkg.surfacelinux.com/fedora/linux-surface.repo 2>/dev/null || true

echo -e "Installing kernel-surface, iptsd, libwacom-surface, surface-secureboot..."
sudo dnf install -y --allowerasing \
  kernel-surface \
  iptsd \
  libwacom-surface \
  surface-secureboot \
  surface-control

echo -e "Enabling iptsd touch and stylus daemon..."
sudo systemctl enable --now iptsd

# -----------------------------------------------------------------------------
# 2. Inject Surface Pro Flex Keyboard Pre-Shared Bluetooth Keys
# -----------------------------------------------------------------------------
echo -e "\n${BOLD}[2/7] Provisioning Surface Pro Flex Keyboard wireless keys...${RESET}"
HOST_MAC="40:C7:3C:2F:8D:6F"
DEVICE_MAC="FE:C5:9D:FC:98:83"
BT_DIR="/var/lib/bluetooth/${HOST_MAC}/${DEVICE_MAC}"

sudo mkdir -p "${BT_DIR}"
sudo chmod 700 /var/lib/bluetooth "/var/lib/bluetooth/${HOST_MAC}" "${BT_DIR}"

sudo tee "${BT_DIR}/info" > /dev/null << 'EOF'
[General]
Name=Surface Pro Flex Keyboard
Appearance=0x03c1
AddressType=static
SupportedTechnologies=LE;
Trusted=true
Blocked=false
Services=00001800-0000-1000-8000-00805f9b34fb;00001801-0000-1000-8000-00805f9b34fb;0000180a-0000-1000-8000-00805f9b34fb;0000180f-0000-1000-8000-00805f9b34fb;00001812-0000-1000-8000-00805f9b34fb;

[IdentityResolvingKey]
Key=431BAC54CCE2EA1AEFB235BE3144CA8B

[LongTermKey]
Key=47972653016AF21CF7C38A192E3A4930
Authenticated=1
EncSize=16
EDiv=62649
Rand=5837191137475359221

[LocalSignatureKey]
Key=6D49B52312B30EB0757454839C97E40D
Counter=0
Authenticated=false
EOF

sudo chmod 600 "${BT_DIR}/info"
sudo systemctl restart bluetooth
echo -e "${GREEN}✓ Flex Keyboard keys provisioned for detached Bluetooth typing.${RESET}"

# -----------------------------------------------------------------------------
# 3. System Desktop Packages & Hardware Acceleration
# -----------------------------------------------------------------------------
echo -e "\n${BOLD}[3/7] Installing UI packages and Intel Xe hardware acceleration...${RESET}"
sudo dnf install -y \
  waybar \
  fuzzel \
  mako \
  brightnessctl \
  iio-sensor-proxy \
  wl-clipboard \
  intel-media-driver \
  libva-utils \
  alacritty \
  jq \
  python3 \
  git \
  patch

# -----------------------------------------------------------------------------
# 4. On-Screen Keyboard (wvkbd)
# -----------------------------------------------------------------------------
echo -e "\n${BOLD}[4/7] Installing on-screen keyboard (wvkbd)...${RESET}"
if sudo dnf copr enable -y fed500/wvkbd 2>/dev/null && sudo dnf install -y wvkbd 2>/dev/null; then
    echo -e "${GREEN}✓ wvkbd installed via Copr.${RESET}"
else
    echo -e "${YELLOW}[!] Copr package unavailable; building wvkbd from source...${RESET}"
    sudo dnf install -y cairo-devel pango-devel libxkbcommon-devel wayland-devel wayland-protocols-devel @development-tools
    BUILD_DIR=$(mktemp -d)
    git clone https://github.com/jjsullivan5196/wvkbd.git "$BUILD_DIR/wvkbd"
    make -C "$BUILD_DIR/wvkbd"
    sudo make -C "$BUILD_DIR/wvkbd" install
    rm -rf "$BUILD_DIR"
    echo -e "${GREEN}✓ wvkbd built and installed to /usr/local/bin.${RESET}"
fi

# -----------------------------------------------------------------------------
# 5. Compile & Install niri-tablet (Touchscreen Gestures)
# -----------------------------------------------------------------------------
echo -e "\n${BOLD}[5/7] Building niri-tablet with touchscreen gestures...${RESET}"
sudo dnf install -y \
  cargo \
  rust \
  clang \
  pkgconf-pkg-config \
  wayland-devel \
  wayland-protocols-devel \
  libxkbcommon-devel \
  libinput-devel \
  mesa-libGL-devel \
  mesa-libEGL-devel \
  pango-devel \
  cairo-devel \
  libseat-devel \
  libdisplay-info-devel \
  pipewire-devel

NIRI_BUILD_DIR=$(mktemp -d)
echo -e "Cloning niri v26.04 into ${NIRI_BUILD_DIR}..."
git clone --branch v26.04 --depth 1 https://github.com/niri-wm/niri.git "$NIRI_BUILD_DIR/niri"

echo -e "Applying 20 niri-tablet touchscreen patches..."
for p in "$REPO_DIR"/patches/*.patch; do
    echo -e "  -> Applying $(basename "$p")..."
    patch -Np1 -d "$NIRI_BUILD_DIR/niri" -i "$p"
done

echo -e "Compiling niri-tablet (this will take ~3-5 minutes)..."
cargo build --release --manifest-path "$NIRI_BUILD_DIR/niri/Cargo.toml"

echo -e "Installing niri-tablet binaries and session desktop files..."
sudo cp "$NIRI_BUILD_DIR/niri/target/release/niri" /usr/local/bin/niri
sudo cp "$NIRI_BUILD_DIR/niri/resources/niri-session" /usr/local/bin/niri-session
sudo cp "$NIRI_BUILD_DIR/niri/resources/niri.desktop" /usr/share/wayland-sessions/niri.desktop
sudo cp "$NIRI_BUILD_DIR/niri/resources/niri-portals.conf" /usr/share/xdg-desktop-portal/ 2>/dev/null || true

rm -rf "$NIRI_BUILD_DIR"
echo -e "${GREEN}✓ niri-tablet installed successfully.${RESET}"

# -----------------------------------------------------------------------------
# 6. Deploy Tablet Helper Scripts & Systemd User Service
# -----------------------------------------------------------------------------
echo -e "\n${BOLD}[6/7] Installing orientation & OSK helper daemons...${RESET}"
mkdir -p "${USER_HOME}/.local/bin"
mkdir -p "${USER_HOME}/.config/systemd/user"

cp "$REPO_DIR/scripts/niri-osk.sh" "${USER_HOME}/.local/bin/niri-osk.sh"
cp "$REPO_DIR/scripts/niri-rotate.sh" "${USER_HOME}/.local/bin/niri-rotate.sh"
chmod +x "${USER_HOME}/.local/bin/"*.sh

# Symlink to /usr/local/bin for global accessibility
sudo ln -sf "${USER_HOME}/.local/bin/niri-osk.sh" /usr/local/bin/niri-osk
sudo ln -sf "${USER_HOME}/.local/bin/niri-rotate.sh" /usr/local/bin/niri-rotate

cat << 'EOF' > "${USER_HOME}/.config/systemd/user/niri-rotate.service"
[Unit]
Description=Surface Pro 10 Auto-Rotate Daemon
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=%h/.local/bin/niri-rotate.sh
Restart=always
RestartSec=2s

[Install]
WantedBy=graphical-session.target
EOF

chown -R "${REAL_USER}:${REAL_USER}" "${USER_HOME}/.local" "${USER_HOME}/.config"

# Enable systemd user service for auto-rotation
sudo -u "${REAL_USER}" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" systemctl --user daemon-reload 2>/dev/null || true
sudo -u "${REAL_USER}" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" systemctl --user enable niri-rotate.service 2>/dev/null || true

# -----------------------------------------------------------------------------
# 7. Deploy Tablet Dotfiles
# -----------------------------------------------------------------------------
echo -e "\n${BOLD}[7/7] Deploying touch-optimized dotfiles...${RESET}"
mkdir -p "${USER_HOME}/.config/"{niri,waybar,fuzzel,mako}

cp "$REPO_DIR/dotfiles/niri/config.kdl" "${USER_HOME}/.config/niri/config.kdl"
cp "$REPO_DIR/dotfiles/waybar/config.jsonc" "${USER_HOME}/.config/waybar/config.jsonc"
cp "$REPO_DIR/dotfiles/waybar/style.css" "${USER_HOME}/.config/waybar/style.css"
cp "$REPO_DIR/dotfiles/fuzzel/fuzzel.ini" "${USER_HOME}/.config/fuzzel/fuzzel.ini"
cp "$REPO_DIR/dotfiles/mako/config" "${USER_HOME}/.config/mako/config"

chown -R "${REAL_USER}:${REAL_USER}" "${USER_HOME}/.config"

echo -e "\n${BOLD}${GREEN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}   Setup Finished Successfully!                                 ${RESET}"
echo -e "${BOLD}${GREEN}================================================================${RESET}"
echo -e "Next steps:"
echo -e "  1. ${BOLD}Reboot your Surface Pro 10${RESET}:"
echo -e "     ${YELLOW}sudo reboot${RESET}"
echo -e "  2. ${BOLD}Secure Boot Note${RESET}: If a blue MOK screen appears on reboot:"
echo -e "     Select ${YELLOW}Enroll MOK${RESET} -> ${YELLOW}Continue${RESET} -> ${YELLOW}Yes${RESET} -> Password: ${YELLOW}surface${RESET}"
echo -e "  3. ${BOLD}Login Screen (SDDM / GDM)${RESET}:"
echo -e "     Select the ${YELLOW}Niri${RESET} session from the desktop/session selector."
echo -e "  4. ${BOLD}Wireless Flex Keyboard${RESET}:"
echo -e "     Detach the keyboard, hold ${YELLOW}Esc${RESET} for 4 seconds until the Fn LED flashes."
echo -e "     It will connect wirelessly over Bluetooth with the pre-shared keys."
