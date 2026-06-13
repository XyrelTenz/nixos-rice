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

  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # qylock SDDM theme
  programs.qylock = {
    enable = true;
    theme = "clockwork";
    sddm.enable = true;        # installs theme + sets it as active SDDM theme
    quickshell.enable = true;  # adds `qylock-lock` to PATH

    themeOptions = {
      clockwork.orbital = {
        themeMode = "dark";
        enableWindup = true;
      };
    };
  };

  # Hardware
  hardware.graphics.enable = true;
  hardware.bluetooth.enable = true;

  # XDG desktop portal
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
}
