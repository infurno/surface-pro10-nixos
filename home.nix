{ config, pkgs, lib, serpantinum, ... }:

{
  imports = [ serpantinum.homeManagerModules.default ];

  home.username = "hal";
  home.homeDirectory = "/home/hal";
  home.stateVersion = "24.11";
  # Put ~/.local/bin and mise shims on PATH for omp (oh-my-pi)
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

  # Essential user tools
  home.packages = with pkgs; [
    kitty
    mise
    git
    gh
    btop
    neovim
    starship
    eza
    bat
    ripgrep
    fzf
  ];
}
