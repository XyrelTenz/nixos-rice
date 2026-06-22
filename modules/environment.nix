{ config, lib, pkgs, username, timezone, ... }:

{
  time.timeZone = timezone;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    HYPRLAND_CONFIG = "/home/${username}/.config/hypr/hyprland.lua";
    QML2_IMPORT_PATH = "/run/current-system/sw/lib/qt-6/qml";
    QML_IMPORT_PATH  = "/run/current-system/sw/lib/qt-6/qml";
  };

  # Registers fish in /etc/shells so it can be used as a login shell
  programs.fish.enable = true;
  programs.zoxide.enable = true;

  # Enable nix-ld to run unpatched dynamic binaries downloaded by rustup
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
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
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXtst
    libxcb
    libxshmfence
  ];
}
