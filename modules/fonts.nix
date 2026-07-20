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
    victor-mono
    comic-mono
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Lilex Nerd Font" "Lilex" "IBM Plex Mono" ];
      sansSerif = [ "IBM Plex Sans" ];
    };
  };
}
