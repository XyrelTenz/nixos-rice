{ config, lib, pkgs, username, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "adbusers" "kvm" "docker" ];
    shell = pkgs.fish;
  };
}
