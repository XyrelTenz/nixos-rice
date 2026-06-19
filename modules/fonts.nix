{ config, lib, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    material-symbols
    rubik
    nerd-fonts.symbols-only
    nerd-fonts.jetbrains-mono
    ibm-plex
    lilex
    nerd-fonts.lilex
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Lilex Nerd Font" "Lilex" "IBM Plex Mono" ];
      sansSerif = [ "IBM Plex Sans" ];
    };
  };
}
