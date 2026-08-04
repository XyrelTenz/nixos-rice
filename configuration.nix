{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # Make the flake's nixpkgs input available to nixd through <nixpkgs>.
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  imports = [
    ./hardware-configuration.nix
    ./modules/boot.nix
    ./modules/networking.nix
    ./modules/desktop.nix
    ./modules/audio.nix
    ./modules/fonts.nix
    ./modules/users.nix
    ./modules/packages.nix
    ./modules/environment.nix
    ./modules/services.nix
  ];

  system.stateVersion = "26.05";
}
