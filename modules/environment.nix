{ config, lib, pkgs, username, timezone, ... }:

{
  time.timeZone = timezone;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    
    substituters = [
      "https://cache.nixos.org"
      "https://attic.xuyh0120.win/lantian"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
    
    permittedInsecurePackages = [
      "pnpm-10.34.0"
    ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    HYPRLAND_CONFIG = "/home/${username}/.config/hypr/hyprland.lua";
    QML2_IMPORT_PATH = "/run/current-system/sw/lib/qt-6/qml";
    QML_IMPORT_PATH  = "/run/current-system/sw/lib/qt-6/qml";

    PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
    PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/query-engine";
    PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines}/lib/libquery_engine.node";
    PRISMA_FMT_BINARY = "${pkgs.prisma-engines}/bin/prisma-fmt";
  };

  programs.fish.enable = true;
  programs.zoxide.enable = true;

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    extraConfig = ''
      # Mouse support
      set -g mouse on
      set -g history-limit 10000

      # Statusline on top
      set -g status-position top

      # True color support
      set -g default-terminal "tmux-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Fallback warm pill theme (overridden by wallcolors on each wallpaper change)
      # Nerd Font rounded caps: U+E0B6 = , U+E0B4 = 
      set -g status-style 'bg=default fg=#e6d6cb'
      set -g status-left '#[fg=#e0563b,bg=default]#[fg=#1c120c,bg=#e0563b,bold] #S #[fg=#e0563b,bg=default] '
      set -g status-left-length 30
      set -g window-status-current-format '#[fg=#e0563b,bg=default]#[fg=#1c120c,bg=#e0563b,bold] #I:#W #[fg=#e0563b,bg=default]'
      set -g window-status-current-style '
      set -g window-status-style 'fg=#594636'
      set -g window-status-format ' #I:#W '
      set -g status-right '#[fg=#e0563b,bg=default]#[fg=#1c120c,bg=#e0563b,bold] %H:%M #[fg=#e0563b,bg=default]#[fg=#594636,bg=default] %d-%b-%y '
      set -g status-right-length 60
      set -g pane-border-style 'fg=#2e231b'
      set -g pane-active-border-style 'fg=#e0563b'
      set -g message-style 'bg=#2e231b,fg=#e6d6cb'

      # Source wallcolors-generated colors — overrides fallback above automatically
      # whenever the wallpaper changes (wallcolors.py calls tmux source-file live).
      if-shell "test -f $HOME/.cache/ricelin/tmux-colors.conf" \
        "source-file $HOME/.cache/ricelin/tmux-colors.conf"
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    stdenv.cc.cc.lib
    zlib
    fuse3
    alsa-lib
    at-spi2-core
    dbus
    glib
    gtk3
    libGL
    libappindicator-gtk3
    libnotify
    libxcb
    libxkbcommon
    mesa
    nspr
    nss
    pango
    pipewire
    systemd
    icu
    openssl
    libX11
    libxkbfile
    libSM
    libICE
    xcbutilcursor
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXtst
    libxshmfence
    
    libpulseaudio
    fontconfig
    freetype
    libxml2
    expat
    libpng
    libbsd
    libuuid
    libdrm
    libsecret
    libXcomposite
    vulkan-loader
  ];
}
