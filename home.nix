{ config, pkgs, lib, serpantinum, ... }:

let
  # Mole for Linux (system clean, app uninstall, disk analyzer - mo / mole)
  mole = pkgs.stdenv.mkDerivation {
    pname = "mole";
    version = "unstable-2026";
    src = pkgs.fetchFromGitHub {
      owner = "ccyisafool";
      repo = "mole-for-ubuntu-and-friends";
      rev = "67b2039f1f64fa86ec0ce0d320bf83dfd4c6f442";
      hash = "sha256-1nnX0LoRFOt4GUyHiZXR2hI9K1LU+UTs2LYJT0fUFdo=";
    };
    installPhase = ''
      mkdir -p $out/bin $out/share/mole-ubuntu
      cp -r * $out/share/mole-ubuntu/
      ln -s $out/share/mole-ubuntu/mo $out/bin/mo
      ln -s $out/share/mole-ubuntu/mo $out/bin/mole
      chmod +x $out/share/mole-ubuntu/mo
    '';
  };
in
{
  imports = [ serpantinum.homeManagerModules.default ];

  home.username = "hal";
  home.homeDirectory = "/home/hal";
  home.stateVersion = "24.11";

  # Put ~/.local/bin and mise shims on PATH for omp and agent CLIs
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/mise/shims"
  ];

  # Serpantinum Desktop Shell (Liquid Glass theme, top modular bar)
  programs.serpantinum = {
    enable = true;
    settings = {
      bar.position = "top";
      bar.width = 100;
      bar.opacity = 72;
      bar.style = "modular";

      theme.activePreset = "Liquid Glass";
      theme.borderRadius = 14;
      theme.fontFamily = "JetBrainsMono Nerd Font";
      theme.colors = {
        base = "#161618";
        mantle = "#0c0c0e";
        crust = "#050506";
        text = "#f5f5f7";
        subtext0 = "#a1a1a6";
        subtext1 = "#d2d2d7";
        surface0 = "#242428";
        surface1 = "#2e2e33";
        surface2 = "#3a3a40";
        overlay0 = "#5b6472";
        overlay1 = "#7a8394";
        overlay2 = "#86868b";
        blue = "#0a84ff";
        sapphire = "#409cff";
        teal = "#64d2ff";
        green = "#32d74b";
        yellow = "#ffd60a";
        peach = "#ff9f0a";
        red = "#ff453a";
        maroon = "#ff6961";
        mauve = "#bf5af2";
        pink = "#d47cf5";
      };

      wallpaperDir = "/home/hal/Pictures/Wallpapers";
    };
  };

  # Theming: Cursors & GTK Dark Theme
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.theme = config.gtk.theme;
  };

  # Automatically hook mise in bash interactive sessions
  programs.bash = {
    enable = true;
    initExtra = ''
      if command -v mise >/dev/null 2>&1; then
        eval "''$(mise activate bash)"
      fi
    '';
  };

  # Declaratively manage niri config.kdl
  xdg.configFile."niri/config.kdl" = {
    source = ./dotfiles/niri/config.kdl;
    force = true;
  };

  # Pre-configure all AI agent CLIs (omp, claude, codex, gemini, copilot, etc.)
  xdg.configFile."mise/config.toml".text = ''
    [tools]
    "aqua:modem-dev/hunk" = "latest"
    claude = "latest"
    codex = "latest"
    copilot = "latest"
    crush = "latest"
    gemini = { version = "latest", allow_builds = ["@github/keytar", "node-pty"] }
    gh = "latest"
    "github:can1357/oh-my-pi" = "latest"
    node = "26.8.1"
    "npm:@xai-official/grok" = "latest"
    opencode = "latest"

    [settings.upgrade]
    auto_prune = false
  '';

  # Dedicated Web Apps / PWAs (Chromium App Mode)
  xdg.desktopEntries = {
    discord = {
      name = "Discord";
      exec = "${pkgs.chromium}/bin/chromium --app=https://discord.com/app";
      icon = "discord";
      categories = [ "Network" "Chat" ];
    };
    whatsapp = {
      name = "WhatsApp";
      exec = "${pkgs.chromium}/bin/chromium --app=https://web.whatsapp.com";
      icon = "whatsapp";
      categories = [ "Network" "Chat" ];
    };
    x-twitter = {
      name = "X";
      exec = "${pkgs.chromium}/bin/chromium --app=https://x.com";
      icon = "twitter";
      categories = [ "Network" "Feed" ];
    };
    zoom-web = {
      name = "Zoom";
      exec = "${pkgs.chromium}/bin/chromium --app=https://app.zoom.us/wc";
      icon = "zoom";
      categories = [ "Network" "VideoConference" ];
    };
    youtube = {
      name = "YouTube";
      exec = "${pkgs.chromium}/bin/chromium --app=https://youtube.com";
      icon = "youtube";
      categories = [ "AudioVideo" ];
    };
    teams = {
      name = "Microsoft Teams";
      exec = "${pkgs.chromium}/bin/chromium --app=https://teams.microsoft.com";
      icon = "teams";
      categories = [ "Network" "Chat" ];
    };
    outlook = {
      name = "Microsoft Outlook";
      exec = "${pkgs.chromium}/bin/chromium --app=https://outlook.live.com/mail/";
      icon = "ms-outlook";
      categories = [ "Office" "Email" ];
    };
    google-messages = {
      name = "Google Messages";
      exec = "${pkgs.chromium}/bin/chromium --app=https://messages.google.com/web";
      icon = "messages";
      categories = [ "Network" "Chat" ];
    };
    google-maps = {
      name = "Google Maps";
      exec = "${pkgs.chromium}/bin/chromium --app=https://maps.google.com";
      icon = "maps";
      categories = [ "Utility" ];
    };
    google-photos = {
      name = "Google Photos";
      exec = "${pkgs.chromium}/bin/chromium --app=https://photos.google.com";
      icon = "photos";
      categories = [ "Graphics" "Photography" ];
    };
    tailscale-admin = {
      name = "Tailscale Admin";
      exec = "${pkgs.chromium}/bin/chromium --app=https://login.tailscale.com/admin";
      icon = "network-vpn";
      categories = [ "Settings" "Network" ];
    };
  };

  # Full Application & Tool Suite (Exact parity with rogue)
  home.packages = with pkgs; [
    # ------------------------------------------------------------- Web Browsers
    brave
    chromium
    firefox

    # --------------------------------------------------- Media, Audio & Video
    vlc
    mpv
    feishin
    easyeffects
    obs-studio
    pavucontrol
    imv

    # ----------------------------------------------- Productivity & Office/Notes
    obsidian
    xournalpp
    rnote
    evince
    pinta
    kdePackages.dolphin
    nautilus
    kdePackages.ark
    swappy

    # --------------------------------------------------- Communication & Social
    thunderbird
    chatterino2
    localsend
    rustdesk-flutter
    librepods

    # ------------------------------------------------------- Gaming & Emulation
    lutris
    prismlauncher
    winetricks

    # ------------------------------------------------------- Terminal Emulators
    foot
    kitty
    wezterm

    # ------------------------------------------------------------ Text Editors
    neovim
    vim-full

    # ------------------------------------------------- Terminal Apps & Multiplexers
    yazi
    btop
    lazydocker
    dua
    lazygit
    aerc
    himalaya
    zellij
    tmux

    # ----------------------------------------- Developer Runtimes & Compilers
    nodejs_22
    python3
    uv
    go
    rustc
    cargo
    clang
    llvm
    gcc
    gnumake
    cmake
    mise
    gh
    git

    # ------------------------------------------------- Search, Prompt & Helpers
    starship
    zoxide
    fzf
    eza
    bat
    ripgrep
    fd
    glow
    tldr
    tokei
    nixfmt
    jq
    yq-go

    # --------------------------------------------------- Media & CLI Processors
    ffmpeg
    ffmpegthumbnailer
    imagemagick
    yt-dlp

    # --------------------------------------------------- Diagnostics & Transfer
    wget
    curl
    curlie
    httpie
    croc
    bandwhich
    bmon
    doggo
    rsync
    rclone
    unzip
    tree
    procs
    dust
    duf
    fastfetch
    cpufetch
    clinfo
    cyme
    hyperfine
    difftastic

    # --------------------------------------------------------- Core Utilities
    syncthing
    mole
  ];

  # ----------------------------------------------------------------- syncthing --
  # Continuous background file synchronization (syncthing serve)
  # Matches rogue/gambit setup; config is managed via GUI at http://127.0.0.1:8384
  systemd.user.services.syncthing = {
    Unit = {
      Description = "Syncthing - Open Source Continuous File Synchronization";
      Documentation = [ "man:syncthing(1)" ];
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${pkgs.syncthing}/bin/syncthing serve --no-browser --no-restart";
      Restart = "on-failure";
      RestartSec = 5;
      SuccessExitStatus = "3 4";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
