{ config, pkgs, lib, ... }:

let
  niriOsk = pkgs.writeShellScriptBin "niri-osk" (builtins.readFile ./scripts/niri-osk.sh);
  niriRotate = pkgs.writeShellScriptBin "niri-rotate" (builtins.readFile ./scripts/niri-rotate.sh);
  surfaceWifi = pkgs.writeShellScriptBin "surface-wifi" (builtins.readFile ./scripts/surface-wifi.sh);
  surfaceBluetooth = pkgs.writeShellScriptBin "surface-bluetooth" (builtins.readFile ./scripts/surface-bluetooth.sh);
in
{
  networking.hostName = "fury";
  networking.networkmanager.enable = true;
  # Syncthing local network discovery & sync ports (rogue <-> fury <-> gambit)
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };

  programs.nm-applet.enable = true;
  services.blueman.enable = true;
  # Git System Configuration (allows git operations inside /etc/nixos)
  programs.git = {
    enable = true;
    config = {
      safe.directory = [ "/etc/nixos" "/etc/nixos/*" ];
    };
  };
  # Foreign binary compatibility (allows prebuilt binaries like omp, AppImages, and node-pty to run)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    fuse3
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libGL
    libappindicator-gtk3
    libdrm
    libglvnd
    libnotify
    libpulseaudio
    libunwind
    libusb1
    libuuid
    libxkbcommon
    mesa
    nspr
    nss
    pango
    pipewire
    systemd
    vulkan-loader
    libx11
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    libxcb
    libxkbfile
    libxshmfence
  ];
  # System-wide PATH initialization (ensures ~/.local/bin and mise shims are on PATH for all shells)
  environment.extraInit = ''
    export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
  '';
  # Automatically activate mise in all interactive bash sessions (keeps omp available)
  programs.bash.interactiveShellInit = ''
    if command -v mise >/dev/null 2>&1; then
      eval "''$(mise activate bash)"
    fi
  '';
  # Power Management & Lid Switch Handling (clean S0ix suspend)
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };






  # Dual-Boot systemd-boot with auto-detected Windows 11
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      extraEntries = {
        "windows.conf" = ''
          title Windows 11
          efi /EFI/Microsoft/Boot/bootmgfw.efi
        '';
      };
    };
  };

  # Localization
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Low-Latency Audio via PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Security & Polkit
  security.polkit.enable = true;

  # Enable Niri session with niri-tablet package
  programs.niri = {
    enable = true;
    package = pkgs.niri-tablet;
  };

  # XDG Desktop Portals (Screensharing, file pickers)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = [ "gnome" "gtk" ];
    };
  };

  # Sensor-based Auto-Rotation Daemon (Runs when graphical session starts)
  systemd.user.services.surface-autorotate = {
    description = "Surface Pro 10 Screen Auto-Rotate Daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    path = with pkgs; [
      iio-sensor-proxy
      config.programs.niri.package
      bash
      coreutils
      procps
      python3
      jq
      niriOsk
    ];
    serviceConfig = {
      ExecStart = "${niriRotate}/bin/niri-rotate";
      Restart = "always";
      RestartSec = "2s";
    };
  };

  # Display Manager (greetd with tuigreet)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # Headless Bluetooth Agent (auto-accepts pairing & authentication on the system bus)
  # This is the exact fix from gambit that makes BLE keyboards pair without a full desktop environment
  systemd.user.services.bluetooth-agent = {
    description = "Bluetooth pairing agent (bt-agent)";
    after = [ "bluetooth.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bluez-tools}/bin/bt-agent -c NoInputNoOutput";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };

  # System Environment & Tablet Packages
  environment.systemPackages = with pkgs; [
    # Custom Surface Tablet Scripts
    niriOsk
    niriRotate
    surfaceWifi
    surfaceBluetooth
    appimage-run

    # Virtual Keyboard & UI Components
    wvkbd
    fuzzel
    bluez-tools
    kitty
    git
    gh
    btop
    neovim
    waybar
    mako
    networkmanagerapplet
    blueman
    util-linux

    # Clipboard, Display & Hardware Tools
    wl-clipboard
    brightnessctl
    wireplumber
    libinput
    jq
    python3

    # Stylus & Note-Taking Applications
    xournalpp
    rnote

    # Standard Desktop Apps
    alacritty
    firefox
  ];

  # Fonts for Waybar Icons & UI
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    dejavu_fonts
    font-awesome
  ];

  # Primary User Account
  users.users.hal = {
    isNormalUser = true;
    description = "Hal Borland";
    initialPassword = "nix";
    extraGroups = [ "wheel" "networkmanager" "video" "input" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOachvLQon4o3w5FGc/OAkp/Jz/PYEyqFRK3sDEhyL4X rogue->gambit (nixos)"
    ];
  };

  # Passwordless sudo for convenience
  security.sudo.wheelNeedsPassword = false;
  # Allow unfree packages (Obsidian, Brave, Steam, etc.)
  nixpkgs.config.allowUnfree = true;
  # Tailscale mesh networking
  services.tailscale.enable = true;

  # Docker container runtime
  virtualisation.docker.enable = true;

  # Steam & GameMode gaming platform
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;


  # Nix Package Manager Configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  system.stateVersion = "24.11";
}
