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
  };

  programs.fish.enable = true;
  programs.zoxide.enable = true;

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
