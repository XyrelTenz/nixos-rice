{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # Hyprland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # Enable SDDM with Wayland support
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    extraPackages = with pkgs; [
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-libav
    ];
  };

  # Qylock strictly for SDDM login screen
  programs.qylock = {
    enable = true;
    theme = "pixel-hollowknight";
    sddm.enable = true;
    quickshell.enable = false;
  };

  # Hardware
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.bluetooth.enable = true;

  # UPower daemon for battery tracking
  services.upower.enable = true;

  # XDG desktop portal
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  # GPU Screen Recorder setuid wrapper for KMS capture
  programs.gpu-screen-recorder.enable = true;

  # Flatpak
  services.flatpak.enable = true;

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # GameMode
  programs.gamemode.enable = false;
}
