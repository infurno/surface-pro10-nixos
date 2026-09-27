#!/usr/bin/env bash
# =============================================================================
# Surface Pro 10 for Business - NixOS Automated Installer Runbook
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


echo -e "${BOLD}${BLUE}================================================================${RESET}"
echo -e "${BOLD}${BLUE}   Surface Pro 10 for Business - NixOS Installation Assistant   ${RESET}"
echo -e "${BOLD}${BLUE}================================================================${RESET}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] Error: This script must be run as root.${RESET}" 
   echo -e "    Please run: ${YELLOW}sudo ./install.sh${RESET}"
   exit 1
fi

DISK="/dev/nvme0n1"

if [[ ! -b "$DISK" ]]; then
    echo -e "${RED}[!] Error: Target drive $DISK not found!${RESET}"
    exit 1
fi

echo -e "\n${BOLD}Available block devices on this system:${RESET}"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "$DISK"

echo -e "\n${BOLD}Select installation mode:${RESET}"
echo -e "  ${GREEN}1)${RESET} ${BOLD}Dual-Boot alongside Windows 11${RESET} (Recommended - preserves Windows)"
echo -e "  ${RED}2)${RESET} ${BOLD}Full Disk Wipe${RESET} (Formats entire 2 TB drive with Disko - WIPES WINDOWS)"
read -rp "Enter choice [1 or 2]: " MODE

case "$MODE" in
    1)
        echo -e "\n${BOLD}${GREEN}--- Dual-Boot Setup Selected ---${RESET}"
        echo -e "Ensure you have shrunk partition C: in Windows before proceeding."
        echo -e "\nCurrent partitions on $DISK:"
        parted "$DISK" print

        echo -e "\nPlease enter partition details:"
        read -rp "Windows EFI Partition [default: /dev/nvme0n1p1]: " WIN_EFI
        WIN_EFI=${WIN_EFI:-/dev/nvme0n1p1}

        read -rp "New NixOS Boot Partition to format (e.g. /dev/nvme0n1p4): " NIX_BOOT
        read -rp "New NixOS Root Partition to format (e.g. /dev/nvme0n1p5): " NIX_ROOT

        echo -e "\n${YELLOW}[!] WARNING: Partition $NIX_BOOT and $NIX_ROOT will be FORMATTED (Unencrypted Btrfs).${RESET}"
        read -rp "Type 'YES' to proceed: " CONFIRM
        if [[ "$CONFIRM" != "YES" ]]; then
            echo "Aborted."
            exit 1
        fi

        echo -e "\n${BOLD}[1/5] Formatting NixOS Boot partition...${RESET}"
        mkfs.vfat -F 32 -n NIXBOOT "$NIX_BOOT"

        echo -e "\n${BOLD}[2/5] Formatting Btrfs on root partition and creating subvolumes...${RESET}"
        mkfs.btrfs -f -L nixos "$NIX_ROOT"
        mount "$NIX_ROOT" /mnt

        btrfs subvolume create /mnt/@
        btrfs subvolume create /mnt/@home
        btrfs subvolume create /mnt/@nix
        btrfs subvolume create /mnt/@swap
        umount /mnt

        echo -e "\n${BOLD}[3/5] Mounting subvolumes with zstd compression...${RESET}"
        mount -o compress=zstd:1,noatime,space_cache=v2,subvol=@ "$NIX_ROOT" /mnt
        mkdir -p /mnt/{home,nix,swap,boot,efi}
        mount -o compress=zstd:2,noatime,space_cache=v2,subvol=@home "$NIX_ROOT" /mnt/home
        mount -o compress=zstd:1,noatime,space_cache=v2,subvol=@nix "$NIX_ROOT" /mnt/nix
        mount -o noatime,subvol=@swap "$NIX_ROOT" /mnt/swap

        mount "$NIX_BOOT" /mnt/boot
        mount "$WIN_EFI" /mnt/efi

        echo -e "\n${BOLD}[4/5] Creating 24GB Hibernation Swapfile...${RESET}"
        btrfs filesystem mkswapfile --size 24g /mnt/swap/swapfile
        swapon /mnt/swap/swapfile
        ;;

    2)
        echo -e "\n${BOLD}${RED}--- Full Disk Wipe Selected ---${RESET}"
        echo -e "${RED}[!] WARNING: ALL DATA ON $DISK INCLUDING WINDOWS WILL BE DESTROYED.${RESET}"
        read -rp "Type 'DESTROY_ALL_DATA' to confirm: " CONFIRM
        if [[ "$CONFIRM" != "DESTROY_ALL_DATA" ]]; then
            echo "Aborted."
            exit 1
        fi

        echo -e "\n${BOLD}[1/2] Running Disko partitioning...${RESET}"
        nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
          --mode disko ./disko.nix
        ;;

    *)
        echo -e "${RED}Invalid selection.${RESET}"
        exit 1
        ;;
esac

echo -e "\n${BOLD}[*] Generating hardware configuration base...${RESET}"
nixos-generate-config --no-filesystems --root /mnt

echo -e "\n${BOLD}[*] Copying repository to target /etc/nixos...${RESET}"
mkdir -p /mnt/etc/nixos
cp -a "$REPO_DIR"/. /mnt/etc/nixos/

echo -e "\n${BOLD}[*] Deploying User Dotfiles (Niri, Waybar, Fuzzel, Mako)...${RESET}"
mkdir -p /mnt/home/user/.config/{niri,waybar,fuzzel,mako}
mkdir -p /mnt/home/user/.local/bin

cp "$REPO_DIR"/dotfiles/niri/config.kdl /mnt/home/user/.config/niri/
cp "$REPO_DIR"/dotfiles/waybar/config.jsonc /mnt/home/user/.config/waybar/
cp "$REPO_DIR"/dotfiles/waybar/style.css /mnt/home/user/.config/waybar/
cp "$REPO_DIR"/dotfiles/fuzzel/fuzzel.ini /mnt/home/user/.config/fuzzel/
cp "$REPO_DIR"/dotfiles/mako/config /mnt/home/user/.config/mako/
cp "$REPO_DIR"/scripts/niri-osk.sh /mnt/home/user/.local/bin/
cp "$REPO_DIR"/scripts/niri-rotate.sh /mnt/home/user/.local/bin/
chmod +x /mnt/home/user/.local/bin/*.sh

# Initial ownership for standard user (uid 1000)
chown -R 1000:100 /mnt/home/user 2>/dev/null || true

echo -e "\n${BOLD}${GREEN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}   Starting NixOS Installation via Flake (.#surface-pro10)      ${RESET}"
echo -e "${BOLD}${GREEN}================================================================${RESET}"

nixos-install --flake /mnt/etc/nixos#surface-pro10 --no-root-passwd

echo -e "\n${BOLD}${GREEN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}   Installation Complete!                                       ${RESET}"
echo -e "${BOLD}${GREEN}================================================================${RESET}"
echo -e "You can now reboot into your new NixOS system."
echo -e "\n${BOLD}Next steps after first boot:${RESET}"
echo -e "  1. Log in with user: ${YELLOW}user${RESET} | password: ${YELLOW}nix${RESET}"
echo -e "  2. Change your password immediately: ${YELLOW}passwd${RESET}"
echo -e "  3. Detach Flex Keyboard and hold ${YELLOW}Esc${RESET} for 4 seconds to test wireless typing."
