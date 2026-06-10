{ config, lib, pkgs, ... }:

{
  time.timeZone = "Asia/Manila";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    HYPRLAND_CONFIG = "/home/xyreltenz/.config/hypr/hyprland.lua";
  };
}
