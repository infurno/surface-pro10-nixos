{ config, pkgs, lib, ... }:

let
  niriOsk = pkgs.writeShellScriptBin "niri-osk" (builtins.readFile ./scripts/niri-osk.sh);
  niriRotate = pkgs.writeShellScriptBin "niri-rotate" (builtins.readFile ./scripts/niri-rotate.sh);
  surfaceWifi = pkgs.writeShellScriptBin "surface-wifi" (builtins.readFile ./scripts/surface-wifi.sh);
  surfaceBluetooth = pkgs.writeShellScriptBin "surface-bluetooth" (builtins.readFile ./scripts/surface-bluetooth.sh);
in
{
  networking.hostName = "surface-pro10";
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;
  services.blueman.enable = true;

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
  time.timeZone = "America/New_York";
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

    # Virtual Keyboard & UI Components
    wvkbd
    fuzzel
    bluez-tools
    kitty
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
  users.users.user = {
    isNormalUser = true;
    initialPassword = "nix"; # Change immediately after install via `passwd`
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
  };

  # Nix Package Manager Configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  system.stateVersion = "24.11";
}
